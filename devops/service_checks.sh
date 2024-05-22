#!/bin/bash
ENV_VARIABLE_SRC=$(systemctl --user show-environment | grep SRC_PATH)
if [ -z "$ENV_VARIABLE_SRC" ]; then
  echo "The SRC_PATH variable is empty."
  file_path=$(find / -path '*/.*' -prune -o -name "scpi_sniffer.service" -print 2>/dev/null)
  directory_path=$(dirname "$file_path")
  DEVOPS_DIR=$(cd "${directory_path}/../" && pwd)
  systemctl --user set-environment SRC_PATH=${DEVOPS_DIR}
fi
