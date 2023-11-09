from textwrap import dedent

import pytest
import requests
from infrahouse_toolkit.terraform import terraform_apply
from requests.auth import HTTPBasicAuth

from tests.conftest import (
    LOG,
    TRACE_TERRAFORM,
    DESTROY_AFTER,
    TEST_ROLE_ARN,
    TEST_ZONE,
    UBUNTU_CODENAME,
)

from os import path as osp


@pytest.mark.flaky(reruns=0, reruns_delay=30)
@pytest.mark.timeout(1800)
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
def test_module(http_user, http_password):
    terraform_dir = "test_data/test_module"

    with open(osp.join(terraform_dir, "terraform.tfvars"), "w") as fp:
        fp.write(
            dedent(
                f"""
                role_arn        = "{TEST_ROLE_ARN}"
                test_zone       = "{TEST_ZONE}"
                ubuntu_codename = "{UBUNTU_CODENAME}"
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
        destroy_after=DESTROY_AFTER,
        json_output=True,
        enable_trace=TRACE_TERRAFORM,
    ) as tf_output:
        assert tf_output["release_bucket"]["value"]
        if http_user:
            response = requests.get(f"https://debian-repo-test.{TEST_ZONE}")
            assert response.status_code == 401
            response = requests.get(
                f"https://debian-repo-test.{TEST_ZONE}",
                auth=HTTPBasicAuth(http_user, http_password),
            )
            assert response.status_code == 200
            LOG.info("Response from HTTP server:\n%s", response.text)
            assert "Stay tuned!" in response.text
        else:
            response = requests.get(f"https://debian-repo-test.{TEST_ZONE}")
            assert response.status_code == 200
            LOG.info("Response from HTTP server:\n%s", response.text)
            assert "Stay tuned!" in response.text
