# GPG Signing Key Rotation Runbook

This runbook rotates the GPG key that signs an APT repository managed by this module, with **zero
downtime** for existing and newly-launched clients. It applies to any codename (`noble`, etc.); the
examples use shell variables so you can reuse them verbatim.

Rotate a key when it is approaching expiry, or immediately if it may be compromised.

## Why a naive rotation breaks clients

GPG key expiry is evaluated **client-side, against the client's own copy of the public key**. Once
"now" passes the expiry stamped in the client's keyring, `apt-get update` returns `EXPKEYSIG` and
rejects the repository — regardless of anything done server-side. Re-signing, extending, or swapping
in a new key are all useless to a running instance until it *receives updated public-key material*.

So a safe rotation has two halves, in a strict order:

1. **Distribute trust** for the new key to every client **first** (publish its public key; clients
   fetch the bundle over TLS at boot and on every config-management run).
2. **Switch signing** to the new key **second**, and retire the old key **last** — each step gated by
   verification.

**The one invariant that guarantees zero downtime:** never let the repository be signed by a key set
that some live client does not yet trust. The whole sequence must finish **while the old key is still
valid**, so the repo is continuously signed by at least one un-expired, universally-trusted key.

## How trust and signing work here

- **Published bundle.** `gpg_public_keys` is a `list(string)` of armored public keys. The module
  concatenates them into the single object served at
  `https://release-<codename>.infrahouse.com/DEB-GPG-KEY-release-<codename>.infrahouse.com`. Armored
  blocks concatenate: a client `gpg --dearmor`s the whole thing and trusts a `Release` signed by
  **any** key in it. This is what makes an overlap possible.
- **Trust is TLS-anchored, not fingerprint-pinned.** Clients (cloud-init at first boot, config
  management on every run) fetch that URL over TLS and install whatever it serves. There is no
  fingerprint pin to update, so *publishing the new key into the bundle is the entire client-side
  change* — convergence and fresh boots pick it up automatically.
- **Signing.** `gpg_sign_with` is rendered into `conf/distributions` → `SignWith:`. Because both keys
  share the same uid (packager email), `SignWith:` must list explicit **fingerprints**, not the
  email (which would be ambiguous). `InRelease` then carries one signature per listed fingerprint; a
  client accepts the repo if it trusts **any** one of them.
- **Private keys.** Both old and new private keys live **concatenated** in the one
  `packager-key-<codename>` Secrets Manager secret; `gpg --import` imports all of them. Whatever the
  secret holds at signing time is what *can* sign; `SignWith:` selects which key(s) actually do.

> **Both keys MUST share one passphrase.** The signing homedir uses a single `passphrase-file` with
> `batch` mode, so gpg cannot prompt. If the new key has a different passphrase, signing with it
> fails hard with no fallback. Generate the new key with the **same** passphrase as
> `packager-passphrase-<codename>`.

## The config syntax is the workflow

`gpg_public_keys` and `gpg_sign_with` are written one item per line, with a trailing comma, on
purpose: **adding or retiring a key is a one-line add or delete.** Keep this form — do not collapse a
single-element `join(" ", [...])` back into a bare string.

```hcl
gpg_public_keys = [
  file("./files/DEB-GPG-KEY-infrahouse-noble"),             # K_old
  file("./files/DEB-GPG-KEY-infrahouse-noble-2026-07-04"),  # K_new
]
gpg_sign_with = join(" ", [
  "A627B77600190BA51B903453D37A181B689AD619", # K_old, expires: 2026-07-20
  "F251F649638B680236DCF9BB8FF1CE88CA0D5F6D", # K_new, expires: 2036-07-01
])
```

## Two hosts do the work

`ih-s3-reprepro` mounts the bucket with `s3fs` (FUSE) and shells to `reprepro` — Linux only, so it
cannot run on macOS. The private key never leaves the laptop as a file; it reaches the signer only
through Secrets Manager.

| | **laptop** (operator workstation) | **jumphost** (Linux, e.g. `jumphost.infrahouse`) |
|---|---|---|
| auth | SSO / AWS profile; Terraform provider | EC2 instance role (a `signing_key_reader`) |
| tools | `gpg`, `ih-secrets`, `terraform` | `ih-s3-reprepro` (`s3fs` + `reprepro`) |
| does | generate key; write the secret; run Terraform | re-sign (`ih-s3-reprepro export`) |

You may drive the jumphost commands over SSM instead of SSH if the jumphost is in an account you can
reach.

### Setup

**laptop** — SSO and shared variables (act by **fingerprint**, never by the shared email):

```bash
export AWS_PROFILE=<release-account-admin-profile>
export AWS_REGION=<region>
aws sts get-caller-identity                    # confirm the RIGHT account (ambient creds can shadow!)
CODENAME=noble
BUCKET=infrahouse-release-${CODENAME}
EMAIL="packager-${CODENAME}@infrahouse.com"
OLD_FPR=<fingerprint of the current, expiring key>
```

> Verify the account explicitly. Stray `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` in your shell
> override `AWS_PROFILE` silently — you can end up pointed at the wrong account without noticing.

**jumphost** — instance role handles auth; build the re-sign command once:

```bash
CODENAME=noble
IH="ih-s3-reprepro --bucket infrahouse-release-${CODENAME} \
    --gpg-key-secret-id packager-key-${CODENAME} \
    --gpg-passphrase-secret-id packager-passphrase-${CODENAME}"
```

`reprepro` re-signs `Release` only as a side effect of adding/removing a package. Phases 2–3 change
*which keys sign* but touch no package, so use `export` to force a package-neutral re-sign:

```bash
$IH export ${CODENAME}
```

## Phase 0 — Generate the new key (laptop)

Generate directly into your keyring, sharing the current passphrase. Two keys will share the uid, so
capture the new fingerprint from gpg's status output, not by selecting on email.

```bash
PP="$(ih-secrets --aws-profile "$AWS_PROFILE" get packager-passphrase-${CODENAME})"
NEW_FPR=$(gpg --batch --pinentry-mode loopback --status-fd 1 --gen-key <<EOF | awk '/KEY_CREATED/{print $NF}'
%echo Generating ${CODENAME} rotation key
Key-Type: RSA
Key-Length: 4096
Key-Usage: sign
Subkey-Type: RSA
Subkey-Length: 4096
Subkey-Usage: encrypt
Name-Real: InfraHouse Packager (key for signing Ubuntu ${CODENAME} repository)
Name-Email: ${EMAIL}
Expire-Date: 10y
Passphrase: ${PP}
%commit
EOF
)
echo "K_new fingerprint: $NEW_FPR"
gpg --armor --export "$NEW_FPR" > files/DEB-GPG-KEY-infrahouse-${CODENAME}-$(date +%F)   # public key
```

> Set `Key-Usage: sign` and `Subkey-Usage: encrypt` explicitly. Omitting them yields a key with the
> wrong capabilities.

## Phase 1 — Distribute trust (laptop / Terraform)

The repo is still signed only by the old key; this only teaches clients to *also* trust the new one.

1. Add the new armored public key file as a new line in `gpg_public_keys`. **Do not** touch
   `gpg_sign_with`.
2. Apply (via your normal PR/apply flow). The published `DEB-GPG-KEY-…` object becomes the two-key
   bundle.

**GATE 1** — do not proceed until all pass:

- On a live sample **and** a freshly-launched instance:
  `gpg --show-keys /etc/apt/keyrings/infrahouse.gpg` lists **both** `OLD_FPR` and `NEW_FPR`, and
  `apt-get update` is clean (no `EXPKEYSIG`, no `NO_PUBKEY`).
- Wait at least one config-management interval plus margin so stragglers converge.

## Phase 2 — Dual-sign (both keys sign)

1. **laptop** — append the new private key to the secret (old key stays; order irrelevant). Fetch the
   canonical old key from the secret and append the new one exported from your keyring:

   ```bash
   { ih-secrets --aws-profile "$AWS_PROFILE" get packager-key-${CODENAME}; \
     gpg --armor --export-secret-keys "$NEW_FPR"; } > packager-key.asc
   ih-secrets --aws-profile "$AWS_PROFILE" set packager-key-${CODENAME} packager-key.asc
   rm -f packager-key.asc
   ```

2. **laptop / Terraform** — add `NEW_FPR` as a second line in `gpg_sign_with`; apply.
3. **jumphost** — `$IH export ${CODENAME}`. The toolkit reads the two-key secret and both `SignWith:`
   fingerprints, so `InRelease` carries **two** signatures.

**GATE 2:**

- `aws s3 cp s3://${BUCKET}/dists/${CODENAME}/InRelease - | gpg --verify -` shows **two** good
  signatures (`OLD_FPR` and `NEW_FPR`).
- A client trusting **only** the old key updates cleanly; a client trusting **only** the new key does
  too. Wait one publish/convergence cycle.

## Phase 3 — Retire the old key

**PRE-GATE (do first).** After this phase the repo is signed by the new key **only**, so any box
lacking it breaks. Confirm both delivery paths carry `NEW_FPR`: a **freshly-launched** instance
(cloud-init) and a **long-running** one (config-management convergence). Spot-check across accounts —
the repo is consumed fleet-wide, not just in the release account.

1. **laptop / Terraform** — delete the old fingerprint line from `gpg_sign_with` (leave only
   `NEW_FPR`); apply. Verify at the **S3 origin** (reprepro reads `conf/distributions` from S3, not
   CloudFront):

   ```bash
   aws s3 cp s3://${BUCKET}/conf/distributions - | grep -i signwith   # only NEW_FPR
   ```

2. **laptop** — rewrite the secret to the new key only, so CI signs with it alone:

   ```bash
   gpg --armor --export-secret-keys "$NEW_FPR" > packager-key.asc
   ih-secrets --aws-profile "$AWS_PROFILE" set packager-key-${CODENAME} packager-key.asc
   rm -f packager-key.asc
   ```

3. **jumphost** — `$IH export ${CODENAME}` (confirm it imports **1** secret key now).
4. **Verify (S3, authoritative):**

   ```bash
   aws s3 cp s3://${BUCKET}/dists/${CODENAME}/InRelease - | gpg --verify -   # exactly ONE good sig
   ```

5. **laptop / Terraform** — delete the old key's line from `gpg_public_keys` (the bundle becomes
   new-key-only); apply. Optionally delete the now-unreferenced old key file.
6. **Invalidate CloudFront** so edges stop serving any cached old-signed `InRelease` and pick up the
   new-key-only bundle. Must complete **well before the old key expires**:

   ```bash
   DIST_ID=$(aws cloudfront list-distributions \
     --query "DistributionList.Items[?contains(Aliases.Items, 'release-${CODENAME}.infrahouse.com')].Id | [0]" \
     --output text)
   aws cloudfront create-invalidation --distribution-id "$DIST_ID" --paths "/dists/${CODENAME}/*"
   ```

**GATE 3:**

- After invalidation propagates:
  `curl -s https://release-${CODENAME}.infrahouse.com/dists/${CODENAME}/InRelease | gpg --verify -`
  shows the **single** new-key signature; fleet `apt-get update` clean.
- The old key may now expire harmlessly. Optionally
  `gpg --delete-secret-and-public-key "$OLD_FPR"` from your keyring.

## Timing note: publish race

Each `apply` + `export` forces a republish. Right after a publish, a CloudFront edge can briefly serve
a `Release` whose recorded `Packages.gz` hash/size does not match the `Packages.gz` it serves
(`File has unexpected size … Mirror sync in progress?`). A fresh instance bootstrapping in that
~1–2 minute window can fail `apt-get update` and abandon its lifecycle hook; it self-heals once
propagation settles. Where practical, time each phase's publish away from known instance-launch
activity.

## Rollback

Phases are additive during the overlap, so rollback is reverting the offending step:

- **After Phase 1:** remove the new key from `gpg_public_keys`; apply. The prior trusted set is
  restored.
- **After Phase 2:** revert `gpg_sign_with` to the old fingerprint and re-`export`; drop the new key
  from the secret if desired.
- Never remove a key from the bundle until the *replacement* is verified universally trusted. Keep the
  previous published bundle object versioned in S3.

## Stopgap: extend expiry instead of rotating

If a full rotation cannot be completed and verified with margin before expiry, extend the existing
key's expiry as a temporary measure: in your keyring, `gpg --edit-key "$OLD_FPR"` → `expire`, set a
new date, `save`; re-export the public key into `gpg_public_keys` and re-upload the private key into
the secret (single key, single `SignWith:`); apply and `export`. This buys time to run the real
rotation calmly. Clients still need to *receive* the refreshed public key, so GATE 1's convergence
check applies here too.

## What is safe to defer vs. what is time-critical

Once the repo is **dual-signed** and the whole fleet trusts both keys, the old key's expiry is a
**non-event**: `apt` accepts a `Release` on any one valid signature from a trusted, un-expired key, so
the still-valid new-key signature carries clients through. The genuinely time-critical action before
expiry is **switching `SignWith:` off the old key and re-signing** (so the signer never tries to sign
with an expired key). Dropping the old *public* key from the bundle and the CloudFront invalidation
are cleanup that can follow — do them promptly, but they are not what prevents an outage.
