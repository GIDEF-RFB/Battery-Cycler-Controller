#!/bin/bash

CS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" && pwd)
cd ${CS_DIR}/../../
CONFIG_DIR=$( cd "${CS_DIR}/../../config/" && pwd)
export CONFIG_FILE_PATH=${CONFIG_DIR}/config_params.yaml
export CSID=$1
python3 -m pip install rfb-battery-cycler --upgrade
python3  $CS_DIR/run_cycler.py
