import logging

from infrahouse_core.logging import setup_logging

# "303467602807" is our test account
TEST_ACCOUNT = "303467602807"
# TEST_ROLE_ARN = "arn:aws:iam::303467602807:role/debian-repo-tester"
DEFAULT_PROGRESS_INTERVAL = 10
TRACE_TERRAFORM = False
UBUNTU_CODENAME = "jammy"

LOG = logging.getLogger(__name__)
REGION = "us-east-2"
TEST_ZONE = "ci-cd.infrahouse.com"

setup_logging(LOG, debug=True)
