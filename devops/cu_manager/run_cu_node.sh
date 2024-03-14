#!/bin/bash

CU_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" && pwd)
cd ${CU_DIR}/../../
CONFIG_DIR=$( cd "${CU_DIR}/../../config/" && pwd)
export CONFIG_FILE_PATH=${CONFIG_DIR}/config_params.yaml
python3  $CU_DIR/run_cu_node.py
