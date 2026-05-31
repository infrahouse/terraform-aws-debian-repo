import logging

from infrahouse_core.logging import setup_logging

UBUNTU_CODENAME = "noble"

LOG = logging.getLogger(__name__)

setup_logging(LOG, debug=True)
