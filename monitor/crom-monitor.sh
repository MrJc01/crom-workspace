#!/usr/bin/env bash
# CROM Monitor — Painel admin para monitorar TUDO dos membros
# Requer: root no VPS de membros
set -euo pipefail

LOG_DIR="/var/log/crom-membros"
REG_DIR="${LOG_DIR}/registry"
SESSION_DIR="${LOG_DIR}/sessions"

C_R='\033[0;31m'; C_G='\033[0;32m'; C_Y='\033[1;33m'
C_C='\033[0;36m'; C_P='\033[0;35m'; C_B='\033[1m'
C_D='\033[2m'; NC='\033[0m'

sep() { echo -e "  ${C_D}──────────────────────────────────────────────${NC}"; }

check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        echo -e "  ${C_R}✗ Execute como root${NC}"; exit 1; fi
}

# Ver atividade de TODOS os membros
cmd_all_activity() {
    echo -e "\n  ${C_P}${C_B}📋 ATIVIDADE RECENTE — TODOS OS MEMBROS${NC}\n"
    local lines="${1:-30}"
    if ls "${LOG_DIR}"/*.log &>/dev/null; then
        # Merge e ordena todos os logs por timestamp
        cat "${LOG_DIR}"/*.log 2>/dev/null | sort -t']' -k1 | tail -n "$lines" | sed 's/^/  /'
    else
        echo -e "  ${C_Y}⚠ Nenhum log encontrado${NC}"
    fi
    echo
}

# Ver atividade de um membro específico
cmd_user_activity() {
    local user="${1:-}"
    [[ -z "$user" ]] && { read -rp "  Username: " user; }
    [[ -z "$user" ]] && return
    echo -e "\n  ${C_P}${C_B}📋 ATIVIDADE: ${user}${NC}\n"
    local logfile="${LOG_DIR}/${user}.log"
    if [[ -f "$logfile" ]]; then
        tail -n "${2:-50}" "$logfile" | sed 's/^/  /'
    else
        echo -e "  ${C_Y}⚠ Sem logs para '${user}'${NC}"
    fi
    echo
}

# Monitor em tempo real (live tail)
cmd_live() {
    echo -e "\n  ${C_P}${C_B}🔴 MONITOR AO VIVO (Ctrl+C para sair)${NC}\n"
    if ls "${LOG_DIR}"/*.log &>/dev/null; then
        tail -f "${LOG_DIR}"/*.log 2>/dev/null | sed 's/^/  /'
    else
        echo -e "  ${C_Y}⚠ Sem logs ainda${NC}"
    fi
}

# Ver projetos de todos os membros
cmd_projects() {
    echo -e "\n  ${C_P}${C_B}📁 PROJETOS DE TODOS OS MEMBROS${NC}\n"
    printf "  ${C_B}%-16s %-18s %-10s %-30s${NC}\n" "MEMBRO" "PROJETO" "STACK" "DESCRIÇÃO"
    sep
    for reg in "${REG_DIR}"/*/projects.list; do
        [[ ! -f "$reg" ]] && continue
        local user=$(basename "$(dirname "$reg")")
        while IFS='|' read -r name desc stack date; do
            [[ -z "$name" ]] && continue
            printf "  %-16s %-18s %-10s %-30s\n" "$user" "$name" "$stack" "${desc:0:28}"
        done < "$reg"
    done
    echo
}

# Ver sessões SSH ativas
cmd_sessions() {
    echo -e "\n  ${C_P}${C_B}🔴 SESSÕES ATIVAS${NC}\n"
    who -u 2>/dev/null | sed 's/^/  /' || echo "  Nenhuma"
    echo
    echo -e "  ${C_B}Últimos 15 logins:${NC}"
    sep
    last -n 15 2>/dev/null | sed 's/^/  /'
    echo
}

# Ver comandos bash de um membro (via bash history central)
cmd_bash_history() {
    local user="${1:-}"
    [[ -z "$user" ]] && { read -rp "  Username: " user; }
    [[ -z "$user" ]] && return
    echo -e "\n  ${C_P}${C_B}🖥  COMANDOS BASH: ${user}${NC}\n"
    local hfile="${LOG_DIR}/bash/${user}_commands.log"
    if [[ -f "$hfile" ]]; then
        tail -n "${2:-50}" "$hfile" | sed 's/^/  /'
    else
        echo -e "  ${C_Y}⚠ Sem histórico bash para '${user}'${NC}"
    fi
    echo
}

# Ver gravações de sessão
cmd_recordings() {
    local user="${1:-}"
    echo -e "\n  ${C_P}${C_B}🎬 GRAVAÇÕES DE SESSÃO${NC}\n"
    if [[ -n "$user" ]]; then
        ls -lh "${SESSION_DIR}/${user}"* 2>/dev/null | sed 's/^/  /' || echo "  Nenhuma gravação"
    else
        ls -lhS "${SESSION_DIR}/" 2>/dev/null | head -20 | sed 's/^/  /' || echo "  Nenhuma gravação"
    fi
    echo
    echo -e "  ${C_D}Reproduzir: scriptreplay <timing> <session>${NC}"
    echo
}

# Relatório consolidado
cmd_report() {
    echo -e "\n  ${C_P}${C_B}📊 RELATÓRIO CONSOLIDADO${NC}\n"
    local grp_gid=$(getent group crom-membros 2>/dev/null | cut -d: -f3)
    local total=0 ativos=0 banidos=0
    if [[ -n "$grp_gid" ]]; then
        total=$(awk -F: -v g="$grp_gid" '$4==g' /etc/passwd | wc -l)
        ativos=$(awk -F: -v g="$grp_gid" '$4==g {print $1}' /etc/passwd | while read u; do
            [[ "$(passwd -S "$u" 2>/dev/null | awk '{print $2}')" == "P" ]] && echo x
        done | wc -l)
        banidos=$((total - ativos))
    fi
    echo -e "  ${C_B}MEMBROS${NC}"
    echo -e "    Total:   ${total}"
    echo -e "    Ativos:  ${ativos}"
    echo -e "    Banidos: ${banidos}"
    sep
    echo -e "  ${C_B}PROJETOS${NC}"
    local proj_total=0
    for f in "${REG_DIR}"/*/projects.list; do
        [[ -f "$f" ]] && proj_total=$((proj_total + $(wc -l < "$f")))
    done
    echo -e "    Total: ${proj_total}"
    sep
    echo -e "  ${C_B}LOGS${NC}"
    local log_count=$(ls "${LOG_DIR}"/*.log 2>/dev/null | wc -l)
    local log_size=$(du -sh "${LOG_DIR}" 2>/dev/null | awk '{print $1}')
    echo -e "    Arquivos: ${log_count}"
    echo -e "    Tamanho:  ${log_size}"
    sep
    echo -e "  ${C_B}SERVIDOR${NC}"
    echo -e "    RAM:    $(free -h | awk '/Mem:/ {printf "%s/%s", $3, $2}')"
    echo -e "    Disco:  $(df -h / | awk 'NR==2 {printf "%s/%s (%s)", $3, $2, $5}')"
    echo -e "    Uptime: $(uptime -p)"
    echo
}

# Buscar nos logs
cmd_search() {
    local term="${1:-}"
    [[ -z "$term" ]] && { read -rp "  Buscar: " term; }
    [[ -z "$term" ]] && return
    echo -e "\n  ${C_P}${C_B}🔍 BUSCANDO: '${term}'${NC}\n"
    grep -rn --color=always "$term" "${LOG_DIR}"/*.log 2>/dev/null | tail -30 | sed 's/^/  /' || echo "  Nada encontrado"
    echo
}

show_menu() {
    clear
    echo -e "${C_P}${C_B}"
    echo '  ╔═════════════════════════════════════════════╗'
    echo '  ║   CROM MONITOR — Painel Administrativo      ║'
    echo '  ╚═════════════════════════════════════════════╝'
    echo -e "${NC}"
    echo -e "  ${C_B}ATIVIDADE${NC}"
    echo -e "    ${C_C}1${NC}  Atividade recente (todos)"
    echo -e "    ${C_C}2${NC}  Atividade de um membro"
    echo -e "    ${C_C}3${NC}  Monitor ao vivo (real-time)"
    echo -e "    ${C_C}4${NC}  Buscar nos logs"
    echo -e "\n  ${C_B}MEMBROS${NC}"
    echo -e "    ${C_C}5${NC}  Projetos de todos"
    echo -e "    ${C_C}6${NC}  Comandos bash de um membro"
    echo -e "    ${C_C}7${NC}  Gravações de sessão"
    echo -e "\n  ${C_B}SERVIDOR${NC}"
    echo -e "    ${C_C}8${NC}  Sessões SSH ativas"
    echo -e "    ${C_C}9${NC}  Relatório consolidado"
    echo -e "\n    ${C_C}0${NC}  Sair\n"
}

main() {
    check_root
    while true; do
        show_menu
        read -rp "  Opção: " opt
        case $opt in
            1) cmd_all_activity ;; 2) cmd_user_activity ;;
            3) cmd_live ;; 4) cmd_search ;;
            5) cmd_projects ;; 6) cmd_bash_history ;;
            7) cmd_recordings ;; 8) cmd_sessions ;;
            9) cmd_report ;; 0) exit 0 ;;
            *) echo -e "  ${C_Y}⚠ Inválido${NC}" ;;
        esac
        read -rp "  ${C_D}Enter para continuar...${NC}"
    done
}

# CLI direto
if [[ $# -gt 0 ]]; then check_root
    case "$1" in
        all)        shift; cmd_all_activity "$@" ;;
        user)       shift; cmd_user_activity "$@" ;;
        live)       cmd_live ;;
        search)     shift; cmd_search "$@" ;;
        projects)   cmd_projects ;;
        bash)       shift; cmd_bash_history "$@" ;;
        recordings) shift; cmd_recordings "$@" ;;
        sessions)   cmd_sessions ;;
        report)     cmd_report ;;
        *) echo "Uso: $0 [all|user|live|search|projects|bash|recordings|sessions|report]" ;;
    esac
    exit 0
fi
main
