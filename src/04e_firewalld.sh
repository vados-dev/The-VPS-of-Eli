# --> МОДУЛЬ: FIREWALLD <--
# - управление правилами файрвола: добавление, удаление, проверка покрытия -

###################
### Переменные: ###
###################

_fw_guard() {
    command -v $fwcmd &>/dev/null || { print_err "$FW_NAME не установлен"; return 1; }
    return 0
}
fw_active() {
    systemctl status ${SERVICE_NAME} 2>/dev/null | grep -q "Active: active"
}

fwcheck() {
set -e
#set -o pipefail
_check_fw() {

XMLLINT="/usr/bin/xmllint"; PACKAGE="libxml2"; BASEDIR="/usr/lib/firewalld/xmlschema"; checkdir="/etc/firewalld";
[ ! -f "$XMLLINT" ] && echo "$XMLLINT is not installed, please install the $PACKAGE package." && exit 1;
[ ! -d "$checkdir" ] && echo "Directory \"$checkdir\"' does not exist" && exit 2;
shopt -s nullglob
ANY_FOUND=0;

for keyword in helper icmptype ipset policy service zone ; do
    if [ "$keyword" = "policy" ]; then
       dir="${checkdir%%/}/policies"
    else
       dir="${checkdir%%/}/${keyword}s"
    fi
    if [ ! -d "$dir" ]; then
       echo "  Directory \"$dir\" does not exist."
    continue
    fi

    for f in "$dir/"*.xml ; do
        ANY_FOUND=1;
        "${XMLLINT}" --noout --schema "${BASEDIR}/${keyword}.xsd" "$f" --quiet | grep error >&2 && exit 2
    done
done

test "$ANY_FOUND" = 1;
}
#_check_fw

#local run="_check_fw | grep error";
# ! $run 2>/dev/null || echo "else"
#else echo "err"; exit 1; fi
#|| die "для отображения текста ошибки выполните в консоли [${blub}$run${bnc}]."; # || log_ok "Success" && return 0
}
#fwcheck

fwreload() {
    local run="$fwcmd --reload"; ! $run > /dev/null 2>&1 && die "для отображения текста ошибки выполните в консоли $run" || log_ok "Success"
}
fwperm() {
    local run="$fwcmd --permanent"; ! $run > /dev/null 2>&1 && die "для отображения текста ошибки выполните в консоли $run" || log_ok "Success"
}

_fw_has_rule() {
    local port="$1" proto="${2:-}"
    [[ -z "$port" ]] && return 1
    local pat
    if [[ -n "$proto" ]]; then
        pat="${port}/${proto}"
    else
        pat="${port}"
    fi
    ufw show added 2>/dev/null | grep -Eq "(^|[[:space:]])${pat}([[:space:]]|$)"
}
fw_show_status() {
    _fw_guard || return 0
    print_section "Статус ${FW_NAME}"
    if ! fw_active; then
        log_warn "${FW_NAME}: неактивен"
    else
        log_ok "${FW_NAME}: активен"
    echo ""
    echo -e "  ${bnc}Правила:${nc}"
        ${fwcmd} --list-all #2>/dev/null | grep -v "^Status:" | sed 's/^/  /' || true
    fi
    echo ""
    return 0
}

fw_toggle() {
    _fw_guard || return 0
    print_section "Включить / выключить ${FW_NAME}"
    if fw_active; then
        print_warn "$FW_NAME активен"
        local confirm=""
        ask_yn "Отключить $FW_NAME?" "n" confirm
        [[ "$confirm" != "yes" ]] && return 0
        systemctl disable --now ${FW_SERVICE}
        print_ok "${FW_NAME} отключён"
    else
        print_warn "${FW_NAME} неактивен"
        local ssh_port; ssh_port=$(ssh_get_port)
        if ! _fw_has_rule "$ssh_port" "tcp" && ! _fw_has_rule "$ssh_port"; then
            print_warn "SSH порт ${ssh_port} не найден в правилах!"
            local add=""
            ask_yn "Добавить ${ssh_port}/tcp?" "y" add
            if [[ "$add" == "yes" ]]; then
                ${fwperm} "${ssh_port}/tcp" comment "SSH" 2>/dev/null || true
            fi
        fi
        local confirm=""
        ask_yn "Включить ${FW_NAME}?" "y" confirm
        [[ "$confirm" != "yes" ]] && return 0
        systemctl enable --now ${FW_SERVICE}
        print_ok "${FW_NAME} включён"
    fi
    return 0
}

fw_add_port() {
    _fw_guard || return 0
    print_section "Добавить порт"
    echo -e "  ${bnc}Форматы: 80 / 80/tcp / 80/udp / 80:90/tcp${nc}"
    local port_input="" port_spec=""
    while true; do
        ask_raw "$(printf '  \033[1mПорт:\033[0m ')" port_input
        [[ -z "$port_input" ]] && continue

        port_spec="$port_input"
        if [[ "$port_spec" =~ ^[0-9]+$ ]]; then
            echo -e "  ${bgrn}1)${nc} tcp  ${bgrm}2)${nc} udp  ${bgrn}3)${nc} tcp+udp"
            local proto_ch=""
            ask_raw "$(printf '  \033[1mПротокол?\033[0m ')" proto_ch
            case "$proto_ch" in
                1) port_spec="${port_input}/tcp" ;;
                2) port_spec="${port_input}/udp" ;;
                3) port_spec="${port_input}" ;;
                *) port_spec="${port_input}/tcp" ;;
            esac
        fi

        # - валидация: одиночный порт или диапазон lo:hi, опциональный /tcp|/udp -
        if ! [[ "$port_spec" =~ ^([0-9]+|[0-9]+:[0-9]+)(/tcp|/udp)?$ ]]; then
            print_err "Неверный формат. Примеры: 80, 80/tcp, 80:90/udp"
            continue
        fi
        # - извлечение порта/диапазона без протокола, проверка границ -
        local pp="${port_spec%/*}"
        if [[ "$pp" == *:* ]]; then
            local lo="${pp%:*}" hi="${pp#*:}"
            if (( lo < 1 || lo > 65535 || hi < 1 || hi > 65535 )); then
                print_err "Порты диапазона должны быть в 1-65535"
                continue
            fi
            if (( lo > hi )); then
                print_err "В диапазоне lo:hi должно быть lo <= hi (получено ${lo}:${hi})"
                continue
            fi
        else
            if (( pp < 1 || pp > 65535 )); then
                print_err "Порт должен быть в 1-65535"
                continue
            fi
        fi
        break
    done

    local comment=""
    echo -e "  ${bnc}Комментарий - пометка для чего этот порт (например: nginx, игра). Можно пропустить.${nc}"
    ask "Комментарий (опционально)" "" comment
    if [[ -n "$comment" ]]; then
        ${fwperm} --add-port="${port_spec}" comment "${comment}"
    else
        ${fwperm} --add-port="${port_spec}"
    fi
    print_ok "Добавлено: allow ${port_spec}"
    return 0
}

fw_delete_rule() {
    _fw_guard || return 0
    print_section "Удалить правило"
    ${fwcmd} --list-all #2>/dev/null | grep -v "^Status:" | sed 's/^/  /'
    echo ""
    local num=""
    while true; do
        ask_raw "$(printf '  \033[1mНомер правила:\033[0m ')" num
        [[ "$num" =~ ^[0-9]+$ ]] && break
    done
    local confirm=""
    ask_yn "Удалить #${num}?" "n" confirm
    [[ "$confirm" != "yes" ]] && return 0
    if echo "y" | ufw delete "$num" 2>/dev/null; then
        print_ok "Удалено"
    else
        print_err "Не удалось"
    fi
    return 0
}

fw_check_ports() {
    _fw_guard || return 0
    print_section "Активные порты vs ${FW_NAME}"

    local fw_rules
    fw_rules=$(${fwcmd} --list-ports 2>/dev/null || true)

    local missing_rules=()

    while IFS= read -r line; do
        local proto port proc addr
        local rest

        proto=$(echo "$line" | awk '{print $1}' | sed 's/[0-9]*$//')
        addr=$(echo "$line" | awk '{print $5}')
        port=$(echo "$addr" | grep -oP ':\K[0-9]+$')
        proc=$(echo "$line" | grep -oP 'users:\(\("?\K[^",)]+')
        [[ -z "$proc" ]] && proc="-"

        [[ -z "$proto" || -z "$port" ]] && continue
        # - пропускаем loopback -
        [[ "$addr" =~ ^127\. || "$addr" =~ ^\[::1\] ]] && continue

        if echo "$ufw_rules" | grep -qE "(^|[[:space:]])${port}/${proto}([[:space:]]|$)|(^|[[:space:]])${port}([[:space:]]|$)"; then
            echo -e "  ${GREEN}[OK]${NC} ${port}/${proto}  ${proc}"
        else
            echo -e "  ${YELLOW}[!]${NC}  ${port}/${proto}  ${proc}  ${YELLOW}нет правила${NC}"
            missing_rules+=("${port}:${proto}:${proc}")
        fi
    done < <(ss -tulpn 2>/dev/null | tail -n +2)

    echo ""

    if [[ ${#missing_rules[@]} -eq 0 ]]; then
        print_ok "Все порты покрыты"
        ufw_active || print_warn "UFW неактивен, правила не применяются"
        return 0
    fi

    print_warn "Без правил: ${#missing_rules[@]}"

    local confirm=""
    ask_yn "Добавить все отсутствующие правила?" "n" confirm

    if [[ "$confirm" == "yes" ]]; then
        local item port proto proc rest
        for item in "${missing_rules[@]}"; do
            port="${item%%:*}"
            rest="${item#*:}"
            proto="${rest%%:*}"
            proc="${rest#*:}"

            ufw allow "${port}/${proto}" comment "${proc}" 2>/dev/null || true
            print_ok "Добавлено: ${port}/${proto} (${proc})"
        done
    fi

    ufw_active || print_warn "UFW неактивен, правила не применяются"
    return 0
}

ufw_reset() {
    _ufw_guard || return 0
    print_section "Сброс всех правил"
    print_warn "Все правила будут удалены, UFW отключён!"
    local confirm=""
    ask_yn "Подтвердить?" "n" confirm
    [[ "$confirm" != "yes" ]] && return 0
    echo "y" | ufw reset 2>/dev/null
    print_ok "UFW сброшен"
    return 0
}
