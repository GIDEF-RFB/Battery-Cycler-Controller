#!/bin/bash

CU_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" && pwd)
cd ${CU_DIR}/../../
CONFIG_DIR=$( cd "${CU_DIR}/../../config/" && pwd)
CU_ID=${CONFIG_DIR}/cu_manager/.cu_id
if ! [ -f $CU_ID ]; then
    echo "CU ID file not found"
else
    rm $CU_ID
fi
export CONFIG_FILE_PATH=${CONFIG_DIR}/config_params.yaml
python3  -m pip install --upgrade rfb_cycler_cu_manager
python3  $CU_DIR/run_cu_node.py
