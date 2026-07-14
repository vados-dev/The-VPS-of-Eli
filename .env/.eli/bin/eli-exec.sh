#!/usr/bin/env bash

set -o pipefail

OUT_NAME="The-VPS-of-Eli"
BUILD_ROOT="/etc/VPN/tools"

ELI_ROOT="/root/.eli"
ELI_BIN="bin"

ENV_FILE=${ELI_ROOT}/.eli-env

SRC_NAME="src"

ELI_BIN_PATH=${ELI_ROOT:-"/root/.eli"}/${ELI_BIN:-"bin"}
BUILD_PATH=${BUILD_ROOT:-"/etc/VPN/tools"}/${OUT_NAME:-"The-VPS-of-Eli"}
SRC_DIR=${BUILD_PATH:-"/etc/VPN/tools/The-VPS-of-Eli"}/${SRC_NAME:-"src"}
BUILD_SCRIPT=${BUILD_PATH}/build.sh
OUT_FILE=${ELI_BIN_PATH}/${OUT_NAME:-"The-VPS-of-Eli"}.sh

#######################################
### Подключаем переменные окружения ###
#######################################
#. $ENV_FILE

##################
### Запускалки ###
##################
show_test() {
echo $OUT_FILE
echo $SRC_DIR
echo $BUILD_SCRIPT
exit 0
}

_build() {
    bash ${BUILD_SCRIPT} ${OUT_NAME} ${BUILD_PATH} ${OUT_FILE}
}

_exec() {
    bash ${OUT_FILE}
}

_check(){
    if ! flock -n 9; then
        printstr "Скрипт уже запущен (lock: %s)\n" "${LOCKFILE}"
        return 0
    else
        return 1
    fi
}

show_help() {
    echo -e "${bld} Управление запуском скрипта${byell} ${OUT_NAME}${bnc}."
    echo -e "┌──────────────────────────────────────────────────────────────────┐"
    echo -e "│          Использование: sudo bash ${bgreen}eli${bnc} [${byell}ОПЦИИ${bnc}]                    │"
    echo -e "├──────────────────────────────────────────────────────────────────┤"
    echo -e "│ ${byell}Опции${bnc}:                                                           │"
    echo -e "│   ${byell}build${bnc}                   - Собрать скрипт                       │"
    echo -e "│   ${byell}run${bnc}                     - Запустить скрипт                     │"
    echo -e "│   ${byell}test${bnc}                    - Запустить тестовую функцию и выйти   │"
    echo -e "│   ${byell}help${bnc}                    - Показать эту справку и выйти         │"
    echo -e "│   ${byell}без аргументов${bnc}          - Запустить скрипт                     │"
    echo -e "│                                                                  │"
    echo -e "└──────────────────────────────────────────────────────────────────┘${nc}"
    exit "${EXIT_RC:-0}"
}
#######################
### Основная логика ###
#######################
echo -e ${nc}
if [ "$#" -lt 1 ]; then
        _exec
else
#        if [ "$2" = "-y" ] || [ "$2" = "-Y" ]; then
#                commandConfirmed="true"
#        fi

        if [ "$1" = "build" ]; then
                _build
        elif [ "$1" = "start" ] || [ "$1" = "run" ]; then
                    _exec
        elif [ "$1" = "help" ]; then
                show_help
        elif [ "$1" = "test" ]; then
                show_test
        fi
fi
printf "%s\n" "$dashes"
