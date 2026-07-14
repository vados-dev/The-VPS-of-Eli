#!/usr/bin/env bash
# --> INSTALL <--
# - Устанавливает систему в окружение -

set -o pipefail

HOME_DIR=${HOME:-"~/"}
ELI_ROOT=${HOME_DIR:-"~/.eli"}/.eli
ELI_BIN="${ELI_ROOT}/bin"
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
echo $SCRIPT_DIR
echo $OUT_FILE
echo $SRC_DIR
echo $BUILD_SCRIPT
#exit 0
}

#ls -la ${cur_dir}/.env/.eli/bin
#cat $ENV_FILE
# || true

eli_install() {
    mkdir -p ${ELI_BIN} || echo "Error $0\n"; exit 1;
    cp -rf ${ENV_FILE} ${ELI_ROOT}/
    cp -rf ${cur_dir}/.env/.eli/bin ${ELI_ROOT}/
    cat ${cur_dir}/.env/.bashrc >> ${HOME_DIR}/.bashrc
     source $HOME/.bashrc
    printf "Поздравляю, набор The-VPS-of-ELi установлен!\nНаберите в терминале \"eli\" для получения помощи с командами.\n"
}

show_help() {
    echo -e "${bld} Управление запуском скрипта${byel} ./install.sh ${bnc}."
    echo -e "┌──────────────────────────────────────────────────────────────────┐"
    echo -e "│          Использование: sudo bash ${bgrn}eli${bnc} [${byel}ОПЦИИ${bnc}]                    │"
    echo -e "├──────────────────────────────────────────────────────────────────┤"
    echo -e "│ ${byel}Опции${bnc}:                                                           │"
    echo -e "│   ${byel}install${bnc}                 - Установить набор                     │"
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
        eli_install
else
#        if [ "$2" = "-y" ] || [ "$2" = "-Y" ]; then
#                commandConfirmed="true"
#        fi

        if [ "$1" = "install" ]; then
                eli_install
        elif [ "$1" = "help" ]; then
                show_help
        elif [ "$1" = "test" ]; then
                show_test
        fi
fi
printf "%s\n" "$dashes"

echo -e ${nc}
