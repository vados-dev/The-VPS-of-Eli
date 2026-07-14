#!/usr/bin/env bash
# --> INSTALL <--
# - Устанавливает систему в окружение -

set -euo pipefail

HOME_DIR=${HOME:-"~/"}
ELI_ROOT=${HOME_DIR:-"~/.eli"}
ELI_BIN="bin"
cur_dir=$(cd $(dirname "$0") 2>/dev/null && pwd) || SCRIPT_DIR=".";
ENV_FILE=${cur_dir}/.env/.eli/.eli-env

#######################################
### Подключаем переменные окружения ###
#######################################
. $ENV_FILE

##################
### Запускалки ###
##################

show_test() {
#echo $SCRIPT_DIR
echo $OUT_FILE
echo $SRC_DIR
echo $BUILD_SCRIPT
exit 0
}

_install() {
    ! mkdir -p ${ELI_ROOT}/${ELI_BIN} 2>/dev/null && echo "Error $0\n"; exit 1;
    cp -r ${cur_dir}/.env/.eli ${HOME_DIR}/
    cat ${cur_dir}/.env/.bashrc >> ${HOME_DIR}/.bashrc
    source ~/.bashrc
    printf "Поздравляю, набор The-VPS-of-ELi установлен!\nНаберите в терминале \"eli\" для получения помощи с командами.\n"
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
    echo -e "${bld} Управление запуском скрипта${byel} ${OUT_NAME}${bnc}."
    echo -e "┌──────────────────────────────────────────────────────────────────┐"
    echo -e "│          Использование: sudo bash ${bgrn}eli${bnc} [${byel}ОПЦИИ${bnc}]                    │"
    echo -e "├──────────────────────────────────────────────────────────────────┤"
    echo -e "│ ${byel}Опции${bnc}:                                                           │"
    echo -e "│   ${byel}install${bnc}                 - Установить набор в $(cd ~ && ls -la) │"
    echo -e "│   ${byel}test${bnc}                    - Запустить тестовую функцию и выйти   │"
    echo -e "│   ${byel}help${bnc}                    - Показать эту справку и выйти         │"
    echo -e "│   ${byel}без аргументов${bnc}          - Установить набор                     │"
    echo -e "│                                                                  │"
    echo -e "└──────────────────────────────────────────────────────────────────┘${nc}"
    exit "${EXIT_RC:-0}"
}
#######################
### Основная логика ###
#######################
echo -e ${nc}
if [ "$#" -lt 1 ]; then
        _install
else
#        if [ "$2" = "-y" ] || [ "$2" = "-Y" ]; then
#                commandConfirmed="true"
#        fi

        if [ "$1" = "install" ]; then
                _install
        elif [ "$1" = "help" ]; then
                show_help
        elif [ "$1" = "test" ]; then
                show_test
        fi
fi

printf "%s\n" "$dashes"