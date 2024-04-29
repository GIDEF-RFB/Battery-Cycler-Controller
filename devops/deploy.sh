#!/bin/bash

DEVOPS_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" && pwd )
REPO_ROOT_DIR=$( cd "${DEVOPS_DIR}/../" && pwd)
CONFIG_DIR="${REPO_ROOT_DIR}/config"
ENV_FILE=".cred.env"
DOCKER_FOLDER=./
DOCKER_COMPOSE=docker-compose.yml
CYCLER_SRC_DIR="${REPO_ROOT_DIR}/code/cycler"
INT_RE='^[0-9]+$'
DOCKER_COMPOSE_ARGS="-f ${DEVOPS_DIR}/${DOCKER_FOLDER}/${DOCKER_COMPOSE} --env-file ${CONFIG_DIR}/${ENV_FILE}"
cat /proc/cpuinfo | grep -q "Raspberry Pi Zero W Rev 1.1"
CS_VERSION=$?
CU_SCREEN="cu_manager"
CS_SCREEN="cycler"

ARG1=$1
ARG2=$2
ARG3=$3

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)


initial_deploy () {
    force_stop
    python3 -m pip install --upgrade rfb-can-sniffer
    python3 -m pip install --upgrade rfb-SCPI-sniffer
    python3 -m pip install --upgrade rfb-cycler-cu-manager
    mkdir -p "${REPO_ROOT_DIR}/log"

    if [ ! $CS_VERSION -eq 0 ]; then
        docker compose ${DOCKER_COMPOSE_ARGS} up cache_db db_sync -d
    fi

    check_sniffer "can"
    check_sniffer "scpi"
}

basic_deploy () {
    force_stop
    mkdir -p "${REPO_ROOT_DIR}/log"
    docker compose ${DOCKER_COMPOSE_ARGS} up cache_db db_sync -d
}

instance_new_cycler () {
    check_sniffer "can"
    check_sniffer "scpi"
    export CYCLER_TARGET=cycler_prod

    if [ ! $CS_VERSION -eq 0 ]; then
        docker compose ${DOCKER_COMPOSE_ARGS} run -d -e CSID=${1} --name wattrex_cycler_node_${1} cycler;
    else
        if screen -ls | grep -q "${CS_SCREEN}_${1}"; then
            echo "Screen session '${CS_SCREEN}_${1}' already exists. Attaching..."
            screen -x "${CS_SCREEN}_${1}"
        else
            echo "Creating new screen session '${CS_SCREEN}_${1}'..."
            # Start a new detached screen session and execute the Python script
            IFS="/" read -ra folders <<< "$(pwd)"
            IFS="/" read -ra dev_folders <<< "${DEVOPS_DIR}"
            length=${#folders[@]}
            length_dev=${#dev_folders[@]}
            if (($length_dev > $length)); then
                IFS="/" read -ra folders <<< "${DEVOPS_DIR}"
                IFS="/" read -ra dev_folders <<< "$(pwd)"
            fi
            # Loop through the array of folders and print each one
            for dev_folder in "${dev_folders[@]}"; do
                for index in "${!folders[@]}"; do
                    if [[ "${folders[index]}" == "$dev_folder" ]]; then
                        # echo "Deleting folder: $dev_folder"
                        unset "folders[index]"
                        break
                    fi
                done
            done
            # echo ${folders[*]}
            CS_DIR=$(echo "${folders[@]}" | tr ' ' '/')/cycler/
            if [[ "${#folders[@]}" == "0" ]]; then
                if [[ "${folders[0]}" == "cycler" ]]; then
                    CS_DIR=""
                else
                    CS_DIR="cycler/"
                fi
            fi
            screen -S ${CS_SCREEN}_${1} -h 200 -d -m ./${CS_DIR}run_cycler.sh ${1}
            echo "Screen session '${CS_SCREEN}_${1}' created and Python script launched."
            echo "$(screen -ls)"
        fi
    fi
}

test_cycler () {
    export CYCLER_TARGET=cycler_test
    cp ${CYCLER_SRC_DIR}/tests/log_config_${ARG3}.yaml ${DEVOPS_DIR}/cycler/log_config.yaml
    cp ${CYCLER_SRC_DIR}/tests/test_${ARG3}.py ${CYCLER_SRC_DIR}/tests/test_cycler.py
    docker compose ${DOCKER_COMPOSE_ARGS} build --build-arg UPDATE_REQS=$(date +%s) cycler
    docker compose ${DOCKER_COMPOSE_ARGS} run --rm -e CSID=${1} --name wattrex_cycler_node_test_${1} cycler pytest -s /cycler/code/cycler/tests/test_cycler.py
    exit $?
}

stop_active_cycler () {
    echo "Stopping container..."
    if [ ! $CS_VERSION -eq 0 ]; then
        docker stop wattrex_cycler_node_${1}
        if [[ $? -eq 0 ]]; then
            echo "Removing residual container..."
            docker container rm wattrex_cycler_node_${1}
        fi
    else
        if screen -ls | grep -q "${CS_SCREEN}_${1}"; then
            echo "Stopping screen session '${CS_SCREEN}_${1}'..."
            screen -S "${CS_SCREEN}_${1}" -X quit
        else
            echo "Screen session '${CS_SCREEN}_${1}' not found"
        fi
    fi
}

check_sniffer () {
    if [[ ${ARG2} = "can" ]] || [[ ${1} = "can" ]]; then
        systemctl --user status can_sniffer.service > /dev/null
        if ! [[ $? -eq 0 ]]; then
            echo "Setting up can sniffer"
            systemctl --user set-environment SRC_PATH=${DEVOPS_DIR}
            systemctl --user set-environment CONFIG_FILE_PATH=${CONFIG_DIR}/config_params.yaml
            systemctl --user enable ${DEVOPS_DIR}/can/can_sniffer.service
            systemctl --user start can_sniffer.service
        else
            echo "Can sniffer is working"
        fi
    fi

    if [[ ${ARG2} = "scpi" ]] || [[ ${1} = "scpi" ]]; then
        systemctl --user status scpi_sniffer.service > /dev/null
        if ! [[ $? -eq 0 ]]; then
            echo "Setting up scpi sniffer"
            systemctl --user set-environment SRC_PATH=${DEVOPS_DIR}
            systemctl --user set-environment CONFIG_FILE_PATH=${CONFIG_DIR}/config_params.yaml
            systemctl --user enable ${DEVOPS_DIR}/scpi/scpi_sniffer.service
            systemctl --user start scpi_sniffer.service
        else
            echo "Scpi sniffer is working"
        fi
    fi
}

stop_sniffer () {
    if [[ ${ARG2} = "can" ]] || [[ ${1} = "can" ]]; then
        systemctl --user stop can_sniffer.service &> /dev/null
        systemctl --user disable can_sniffer.service &> /dev/null
        rm -f /dev/mqueue/TX_CAN
    fi

    if [[ ${ARG2} = "scpi" ]] || [[ ${1} = "scpi" ]]; then
        systemctl --user stop scpi_sniffer.service &> /dev/null
        systemctl --user disable scpi_sniffer.service &> /dev/null
        rm -f /dev/mqueue/TX_SCPI
    fi
}

cu_manager () {
    check_sniffer "can"
    check_sniffer "scpi"
    if screen -ls | grep -q "$CU_SCREEN"; then
        echo "Screen session '$CU_SCREEN' already exists. Attaching..."
        screen -x "$CU_SCREEN"
    else
        echo "Creating new screen session '$CU_SCREEN'..."
        # Start a new detached screen session and execute the Python script
        IFS="/" read -ra folders <<< "$(pwd)"
        IFS="/" read -ra dev_folders <<< "${DEVOPS_DIR}"
        length=${#folders[@]}
        length_dev=${#dev_folders[@]}
        if (($length_dev > $length)); then
                IFS="/" read -ra folders <<< "${DEVOPS_DIR}"
                IFS="/" read -ra dev_folders <<< "$(pwd)"
        fi
        # Loop through the array of folders and print each one
        for dev_folder in "${dev_folders[@]}"; do
            for index in "${!folders[@]}"; do
                if [[ "${folders[index]}" == "$dev_folder" ]]; then
                    # echo "Deleting folder: $dev_folder"
                    unset "folders[index]"
                    break
                fi
            done
        done
        # echo ${folders[*]}
        CU_DIR=$(echo "${folders[@]}" | tr ' ' '/')/cu_manager/
        if [[ "${#folders[@]}" == "0" ]]; then
            if [[ "${folders[0]}" == "cu_manager" ]]; then
                CU_DIR=""
            else
                CU_DIR="cu_manager/"
            fi
        fi
        screen -S $CU_SCREEN -h 200 -d -m ./${CU_DIR}run_cu_node.sh
        echo "Screen session '$CU_SCREEN' created and Python script launched."
        echo "$(screen -ls)"
    fi
}

force_stop () {
    if [ ! $CS_VERSION -eq 0 ]; then
        docker compose ${DOCKER_COMPOSE_ARGS} down
    else
        # Stop all screen sessions
        screen -ls | grep -oP '^\s*\d+\.\w+\s+\(Detached\)$' | cut -f1 | while read -r line; do
            screen -S "${line}" -X quit
        done
    fi

    stop_sniffer "can"
    stop_sniffer "scpi"

    rm -f /dev/mqueue/*
}


# MAIN
if ! [ -f "${CONFIG_DIR}/${ENV_FILE}" ]; then
    >&2 echo "[ERROR] .cred.env file not found"
    exit 2
fi

if ! [ -d "${DEVOPS_DIR}/${DOCKER_FOLDER}" ]; then
    >&2 echo "[ERROR] ${DEVOPS_DIR}/${DOCKER_FOLDER} folder not found"
    exit 2
else
    if ! [ -f "${DEVOPS_DIR}/${DOCKER_FOLDER}/${DOCKER_COMPOSE}" ]; then
        >&2 echo "[ERROR] ${DEVOPS_DIR}/${DOCKER_FOLDER}/${DOCKER_COMPOSE} file not found"
        exit 2
    fi
fi

# Check if the required files are present.
required_file_list=("${DEVOPS_DIR}/docker-compose.yml"
                    "${DEVOPS_DIR}/cache_db/createCacheCyclerTables.sql"
                    "${CONFIG_DIR}/.cred.env"
                    "${CONFIG_DIR}/.cred.yaml"
                    )
optional_file_list=("${CONFIG_DIR}/config_params"
                    "${CONFIG_DIR}/scpi/log_config"
                    "${CONFIG_DIR}/cycler/log_config"
                    "${CONFIG_DIR}/cu_manager/log_config"
                    "${CONFIG_DIR}/can/log_config"
                    "${CONFIG_DIR}/db_sync/log_config"
                    )

for file_path in ${required_file_list[@]}
do
    if [ ! -f ${file_path} ]; then
        echo "${file_path} not found"
        exit 1
    fi
done

for file_path in ${optional_file_list[@]}
do
    # echo "Checking ${file_path} file..."
    if test ! -f ${file_path}.yaml ; then
        echo "${file_path} not found, making a copy from example"
        cp ${file_path}_example.yaml ${file_path}.yaml
    fi
done

case ${ARG1} in
    "")
        # echo "Initial Deploy"
        if [ ! $CS_VERSION -eq 0 ]; then
            export CYCLER_TARGET=db_sync_prod
            docker compose ${DOCKER_COMPOSE_ARGS} pull db_sync
            docker compose ${DOCKER_COMPOSE_ARGS} pull cycler
        fi
        initial_deploy
        ;;
    "build")
        # echo "Initial Deploy"
        export CYCLER_TARGET=db_sync_local
        docker compose ${DOCKER_COMPOSE_ARGS} build --build-arg UPDATE_REQS=$(date +%s) db_sync
        initial_deploy
        ;;
    "basic")
        # echo "Initial Deploy"
        export CYCLER_TARGET=db_sync_prod
        docker compose ${DOCKER_COMPOSE_ARGS} pull db_sync
        basic_deploy
        ;;
    "CU")
        # echo "CU Manager"
        cu_manager
        ;;
    "cycler")
        if [[ ${ARG2} =~ $INT_RE ]]; then
            # echo "Cycler ${2}"
            instance_new_cycler "${ARG2}"
        else
            >&2 echo "[ERROR] Invalid Cycler Station ID"
            exit 3
        fi
        ;;
    "sniffer")
        # echo "Check Sniffer"
        if [[ "${ARG2}" = "can" ]] || [[ "${ARG2}" = "scpi" ]]; then
            # echo "Sniffer ${2}"
            check_sniffer "${ARG2}"
        else
            >&2 echo "[ERROR] Invalid sniffer"
            exit 3
        fi
        ;;
    "stop-sniffer")
        # echo "Stop Sniffer"
        if [[ "${ARG2}" = "can" ]] || [[ "${ARG2}" = "scpi" ]]; then
            # echo "Sniffer ${2}"
            stop_sniffer "${ARG2}"
        else
            >&2 echo "[ERROR] Invalid sniffer"
            exit 3
        fi
        ;;
    "stop-cycler")
        # echo "Stop cycler ${ARG2}"
        if [[ ${ARG2} =~ $INT_RE ]]; then
            # echo "Cycler ${2}"
            stop_active_cycler "${ARG2}"
        else
            >&2 echo "[ERROR] Invalid Cycler Station ID"
            exit 3
        fi
        ;;    
    "force-stop")
        # echo "Stop all"
        force_stop
        ;;
    "test")
        if [[ ${ARG2} =~ $INT_RE ]]; then
            # echo "Cycler ${2}"
            test_cycler "${ARG2}"
        else
            >&2 echo "[ERROR] Invalid Cycler Station ID"
            exit 3
        fi
        ;;
    *)
        >&2 echo "[ERROR] Invalid command type: ${ARG1}"
        exit 3
        ;;
esac
