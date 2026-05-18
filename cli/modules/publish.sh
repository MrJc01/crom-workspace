#!/usr/bin/env bash
# CROM Workspace — Módulo de Publicação Web
# Comandos: publish, unpublish, ports

cmd_publish() {
    local name="${1:-}"
    local port="${2:-}"
    local custom_domain="${3:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do projeto: " name; }
    [[ -z "$name" ]] && return
    local pdir="${PROJECTS_DIR}/${name}"
    [[ ! -d "$pdir" ]] && { err "'${name}' não encontrado. Crie primeiro com 'crom-ws init'"; return 1; }
    [[ -z "$port" ]] && { read -rp "  Porta local (ex: 3000): " port; }
    [[ -z "$port" ]] && return

    info "Solicitando publicação para ${name} na porta ${port}..."
    local res
    if res=$(sudo /usr/local/sbin/crom-publish-helper add "$USER_NAME" "$name" "$port" "$custom_domain" 2>&1); then
        if echo "$res" | grep -q "SUCESSO"; then
            local url=$(echo "$res" | grep "SUCESSO" | cut -d: -f2)
            success "Projeto publicado com sucesso!"
            success "URL: http://${url}"
            log_action "PUBLISH_PROJECT" "name=${name} port=${port} url=${url}"
        else
            err "Falha na publicação: $res"
        fi
    else
        err "Erro crítico: $res"
    fi
}

cmd_unpublish() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do projeto: " name; }
    [[ -z "$name" ]] && return
    
    info "Removendo publicação de ${name}..."
    local res
    if res=$(sudo /usr/local/sbin/crom-publish-helper rm "$USER_NAME" "$name" 2>&1); then
        if echo "$res" | grep -q "SUCESSO"; then
            success "Projeto removido da web."
            log_action "UNPUBLISH_PROJECT" "name=${name}"
        else
            err "Falha ao remover: $res"
        fi
    else
        err "Erro crítico: $res"
    fi
}

cmd_ports() {
    echo -e "\n  ${C_P}${C_B}🌐 PROJETOS PUBLICADOS (ECOSSISTEMA)${NC}\n"
    local list=$(sudo /usr/local/sbin/crom-publish-helper list 2>/dev/null)
    if [[ -z "$list" ]]; then
        info "Nenhum projeto publicado no servidor."
        echo
        return
    fi
    printf "  ${C_B}%-8s %-15s %-15s %-35s${NC}\n" "PORTA" "USUÁRIO" "PROJETO" "URL (DOMÍNIO)"
    echo "$list" | while IFS=: read -r port user proj dom; do
        printf "  %-8s %-15s %-15s %-35s\n" "$port" "$user" "$proj" "$dom"
    done
    echo
    log_action "VIEW_PORTS" ""
}
