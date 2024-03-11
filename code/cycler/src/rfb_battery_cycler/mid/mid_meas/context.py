#!/usr/bin/python3
'''
This module manages the constants variables.
Those variables are used in the scripts inside the module and can be modified
in a config yaml file specified in the environment variable with name declared
in system_config_tool.
'''

#######################        MANDATORY IMPORTS         #######################
from __future__ import annotations
#######################         GENERIC IMPORTS          #######################

#######################      SYSTEM ABSTRACTION IMPORTS  #######################
from rfb_logger_tool import Logger, sys_log_logger_get_module_logger
log: Logger = sys_log_logger_get_module_logger(__name__)

#######################       THIRD PARTY IMPORTS        #######################

#######################          PROJECT IMPORTS         #######################
from rfb_config_tool import sys_conf_update_config_params

#######################          MODULE IMPORTS          #######################

######################             CONSTANTS              ######################
# For further information check out README.md

DEFAULT_NODE_PERIOD: int        = 120 # Express in milliseconds
DEFAULT_NODE_NAME: str          = 'MEAS'
DEFAULT_SERIAL_PERIOD: int      = 900 # Express in milliseconds, it has to be over the 800ms

CONSTANTS_NAMES = ('DEFAULT_NODE_PERIOD', 'DEFAULT_NODE_NAME')
sys_conf_update_config_params(context=globals(),
                              constants_names=CONSTANTS_NAMES)
