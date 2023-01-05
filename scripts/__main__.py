#!/usr/bin/python3

import logging

from scripts import installers

logging.basicConfig(level=logging.INFO, format='%(name)s - %(levelname)s - %(message)s')

logger = logging.getLogger(__file__)

logger.info('Starting install scripts')

for installer in installers:
    installer_name = type(installer).__name__
    logger.info(
        f'Running installer: {installer_name}, '
        f'with description: {installer.get_description()}')
    try:
        success = installer()
        logger.info(f'Installer {installer_name} ran with success = {success}')
    except Exception as ex:
        logger.error(f'Error running {installer_name}', exc_info=ex)
