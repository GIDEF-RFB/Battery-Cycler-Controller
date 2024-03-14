#!/usr/bin/python3
"""
Cu Manager
"""
#######################        MANDATORY IMPORTS         #######################

#######################         GENERIC IMPORTS          #######################
import sys
import os
import threading
from signal import signal, SIGINT

#######################       THIRD PARTY IMPORTS        #######################

#######################    SYSTEM ABSTRACTION IMPORTS    #######################
from rfb_logger_tool import sys_log_logger_get_module_logger, SysLogLoggerC, Logger

#######################       LOGGER CONFIGURATION       #######################
repo_dir=os.path.dirname(__file__)+'/../../'
if __name__ == '__main__':
    cycler_logger = SysLogLoggerC(file_log_levels=repo_dir+'/config/cu_manager/log_config.yaml')
log: Logger = sys_log_logger_get_module_logger(__name__)

#######################          MODULE IMPORTS          #######################
sys.path.append(repo_dir+'/../../code')
# from cu_manager.src.rfb_cycler_cu_manager import CuManagerNodeC
from rfb_cycler_cu_manager import CuManagerNodeC

#######################          PROJECT IMPORTS         #######################

#######################              ENUMS               #######################

#######################             CLASSES              #######################

#######################            FUNCTIONS             #######################
cu_manager_node = None #pylint: disable= invalid-name

def signal_handler(sig, frame) -> None: #pylint: disable= unused-argument
    """Called when the user presses Ctrl + C to stop test.

    Args:
        sig ([type]): [description]
        frame ([type]): [description]
    """
    if isinstance(cu_manager_node, CuManagerNodeC):
        log.critical(msg='You pressed Ctrl+C! Stopping test...')
        cu_manager_node.stop()
        sys.exit(0)

if __name__ == '__main__':
    working_flag_event : threading.Event = threading.Event()
    working_flag_event.set()
    cu_manager_node = CuManagerNodeC(working_flag=working_flag_event,
                                          cycle_period=1000,
                                          cu_id_file_path=repo_dir+'/config/cu_manager/.cu_id')
    signal(SIGINT, signal_handler)
    cu_manager_node.run()
