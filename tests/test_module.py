from textwrap import dedent

import pytest
import requests
from infrahouse_toolkit.terraform import terraform_apply
from requests.auth import HTTPBasicAuth

from tests.conftest import (
    LOG,
    TRACE_TERRAFORM,
    UBUNTU_CODENAME,
)

from os import path as osp


@pytest.mark.parametrize(
    "http_user, http_password",
    [
        (
            None,
            None,
        ),
        (
            "foouser",
            "foopass",
        ),
    ],
)
def test_module(
    jumphost, http_user, http_password, keep_after, test_zone_name, test_role_arn
):
    terraform_dir = "test_data/test_module"
    jumphost_role_arn = jumphost["jumphost_role_arn"]["value"]
    jumphost_role_name = jumphost["jumphost_role_name"]["value"]

    with open(osp.join(terraform_dir, "terraform.tfvars"), "w") as fp:
        fp.write(
            dedent(
                f"""
                test_zone          = "{test_zone_name}"
                ubuntu_codename    = "{UBUNTU_CODENAME}"
                jumphost_role_arn  = "{jumphost_role_arn}"
                jumphost_role_name = "{jumphost_role_name}"
                """
            )
        )
        if test_role_arn:
            fp.write(
                dedent(
                    f"""
                    role_arn        = "{test_role_arn}"
                    """
                )
            )
        if http_user:
            fp.write(
                dedent(
                    f"""
                    http_user     = "{http_user}"
                    http_password = "{http_password}" 
                    """
                )
            )

    with terraform_apply(
        terraform_dir,
        destroy_after=not keep_after,
        json_output=True,
        enable_trace=TRACE_TERRAFORM,
    ) as tf_output:
        assert tf_output["release_bucket"]["value"]
        if http_user:
            response = requests.get(f"https://debian-repo-test.{test_zone_name}")
            assert response.status_code == 401
            response = requests.get(
                f"https://debian-repo-test.{test_zone_name}",
                auth=HTTPBasicAuth(http_user, http_password),
            )
            assert response.status_code == 200
            LOG.info("Response from HTTP server:\n%s", response.text)
            assert "Stay tuned!" in response.text
        else:
            response = requests.get(f"https://debian-repo-test.{test_zone_name}")
            assert response.status_code == 200
            LOG.info("Response from HTTP server:\n%s", response.text)
            assert "Stay tuned!" in response.text
