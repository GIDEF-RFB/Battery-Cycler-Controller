#!/bin/bash

# Store the results in an array
file_paths=($(find / -path '*/.*' -prune -o -name "scpi_sniffer.service" -print 2>/dev/null))
directory_path="home/wattrex/"

# Check the number of results
if [ ${#file_paths[@]} -eq 0 ]; then
    echo "No files found."
elif [ ${#file_paths[@]} -eq 1 ]; then
    echo "One file found: ${file_paths[0]}"
    if echo "${file_paths[0]}" | grep -q "home/wattrex"; then
        echo "matched";
        directory_path=$(dirname "${file_paths[0]}")
    fi
else
    echo "Multiple files found:"
    for file_path in "${file_paths[@]}"; do
        echo "$file_path"
        if echo "$file_path" | grep -q "home/wattrex"; then
            echo "matched";
            directory_path=$(dirname "$file_path")
        fi
    done
fi

echo "${directory_path}"
DEVOPS_DIR=$(cd "${directory_path}/../" && pwd)
CONFIG_DIR=$(cd "${directory_path}/../../config/" && pwd)

VARIABLE_CONFIG=$(echo $CONFIG_FILE_PATH)
echo "CONFIG_FILE_PATH VALUE: ${CONFIG_FILE_PATH}"

if [ -z "$VARIABLE_CONFIG" ]; then
  echo "The CONFIG_FILE_PATH variable is empty"
  export CONFIG_FILE_PATH="${CONFIG_DIR}/config_params.yaml"
fi

ENV_VARIABLE_CONFIG=$(systemctl --user show-environment | grep CONFIG_FILE_PATH)
if [ -z "$ENV_VARIABLE_CONFIG" ]; then
  echo "Added config file path to environment: ${CONFIG_FILE_PATH}"
  systemctl --user set-environment CONFIG_FILE_PATH="${CONFIG_DIR}/config_params.yaml"
fi

ENV_VARIABLE_SRC=$(systemctl --user show-environment | grep SRC_PATH)
if [ -z "$ENV_VARIABLE_SRC" ]; then
  echo "The SRC_PATH environment variable is empty."
  systemctl --user set-environment SRC_PATH=${DEVOPS_DIR}
fi

VARIABLE_SRC=$(echo $SRC_PATH)
if [ -z "$VARIABLE_SRC" ]; then
  echo "The SRC_PATH variable is empty"
  export SRC_PATH=${DEVOPS_DIR}
fi
