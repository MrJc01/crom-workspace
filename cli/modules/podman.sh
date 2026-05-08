#!/usr/bin/env bash
# CROM Workspace — Módulo Podman (Quadlets)
# Comandos: podman run/stop/start/rm/list/logs

cmd_podman() {
    local sub="${1:-}"
    [[ -z "$sub" ]] && { cmd_podman_help; return; }
    shift
    case "$sub" in
        run)    cmd_podman_run "$@" ;;
        stop)   cmd_podman_stop "$@" ;;
        start)  cmd_podman_start "$@" ;;
        rm)     cmd_podman_rm "$@" ;;
        list|ls) cmd_podman_list ;;
        logs)   cmd_podman_logs "$@" ;;
        help|-h) cmd_podman_help ;;
        *)      err "Subcomando podman desconhecido: $sub"; cmd_podman_help ;;
    esac
}

cmd_podman_run() {
    local name="${1:-}"
    local image="${2:-}"
    local port="${3:-}"

    [[ -z "$name" ]] && { read -rp "  Nome do serviço: " name; }
    [[ -z "$name" ]] && { err "Nome obrigatório"; return 1; }
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')

    [[ -z "$image" ]] && { read -rp "  Imagem (ex: redis:alpine, n8nio/n8n): " image; }
    [[ -z "$image" ]] && { err "Imagem obrigatória"; return 1; }

    [[ -z "$port" ]] && { read -rp "  Porta exposta (ex: 5678, 6379): " port; }
    [[ -z "$port" ]] && { err "Porta obrigatória"; return 1; }
    [[ ! "$port" =~ ^[0-9]+$ ]] && { err "Porta inválida"; return 1; }

    # Garantir diretório de Quadlets
    mkdir -p "$QUADLET_DIR"

    local quadlet_file="${QUADLET_DIR}/${name}.container"
    local volume_dir="${HOME}/.local/share/crom-volumes/${name}"
    mkdir -p "$volume_dir"

    if [[ -f "$quadlet_file" ]]; then
        warn "Quadlet '${name}' já existe. Use 'crom-ws podman rm ${name}' primeiro."
        return 1
    fi

    info "Gerando Quadlet para '${name}'..."

    cat > "$quadlet_file" <<EOF
[Unit]
Description=CROM Container: ${name}
After=default.target

[Container]
Image=${image}
PublishPort=${port}:${port}
Volume=${volume_dir}:/data:Z
AutoUpdate=registry
Label=crom.project=${name}
Label=crom.owner=${USER_NAME}
Label=crom.port=${port}

[Service]
Restart=always
RestartSec=10
TimeoutStartSec=300

[Install]
WantedBy=default.target
EOF

    info "Recarregando systemd do usuário..."
    systemctl --user daemon-reload

    info "Habilitando e iniciando o serviço..."
    systemctl --user enable --now "${name}.service" 2>/dev/null

    # Verificar se subiu
    sleep 2
    if systemctl --user is-active --quiet "${name}.service" 2>/dev/null; then
        success "Container '${name}' está rodando!"
        success "Imagem: ${image}"
        success "Porta: ${port}"
        success "Volume: ${volume_dir}"
        success "Auto-restart: ATIVO (sobrevive reboot)"
        echo -e "\n  ${C_D}Dica: Para publicar na web, rode:${NC}"
        echo -e "  ${C_C}crom-ws publish ${name} ${port}${NC}\n"
    else
        warn "Serviço criado, mas pode estar ainda baixando a imagem..."
        warn "Verifique com: crom-ws podman logs ${name}"
    fi

    log_action "PODMAN_RUN" "name=${name} image=${image} port=${port}"
}

cmd_podman_stop() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do serviço: " name; }
    [[ -z "$name" ]] && return

    if ! systemctl --user is-enabled --quiet "${name}.service" 2>/dev/null; then
        err "Serviço '${name}' não encontrado."
        return 1
    fi

    systemctl --user stop "${name}.service" 2>/dev/null
    success "Container '${name}' parado."
    info "Para reiniciar: crom-ws podman start ${name}"
    log_action "PODMAN_STOP" "name=${name}"
}

cmd_podman_start() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do serviço: " name; }
    [[ -z "$name" ]] && return

    if ! systemctl --user is-enabled --quiet "${name}.service" 2>/dev/null; then
        err "Serviço '${name}' não encontrado."
        return 1
    fi

    systemctl --user start "${name}.service" 2>/dev/null
    sleep 2
    if systemctl --user is-active --quiet "${name}.service" 2>/dev/null; then
        success "Container '${name}' iniciado!"
    else
        warn "Serviço não subiu. Verifique: crom-ws podman logs ${name}"
    fi
    log_action "PODMAN_START" "name=${name}"
}

cmd_podman_rm() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do serviço para remover: " name; }
    [[ -z "$name" ]] && return

    local quadlet_file="${QUADLET_DIR}/${name}.container"
    if [[ ! -f "$quadlet_file" ]]; then
        err "Quadlet '${name}' não encontrado."
        return 1
    fi

    # Parar e desabilitar
    systemctl --user stop "${name}.service" 2>/dev/null || true
    systemctl --user disable "${name}.service" 2>/dev/null || true

    # Remover arquivo Quadlet
    rm -f "$quadlet_file"
    systemctl --user daemon-reload

    success "Container '${name}' removido do sistema."
    info "Os dados do volume em ~/.local/share/crom-volumes/${name}/ foram preservados."
    log_action "PODMAN_RM" "name=${name}"
}

cmd_podman_list() {
    echo -e "\n  ${C_P}${C_B}🐳 CONTAINERS GERENCIADOS (Quadlets)${NC}\n"

    if [[ ! -d "$QUADLET_DIR" ]] || [[ -z "$(ls -A "$QUADLET_DIR"/*.container 2>/dev/null)" ]]; then
        info "Nenhum container gerenciado."
        info "Use: crom-ws podman run <nome> <imagem> <porta>"
        echo
        return
    fi

    printf "  ${C_B}%-16s %-25s %-8s %-12s${NC}\n" "SERVIÇO" "IMAGEM" "PORTA" "STATUS"
    for qf in "$QUADLET_DIR"/*.container; do
        local sname=$(basename "$qf" .container)
        local img=$(grep '^Image=' "$qf" | cut -d= -f2)
        local port=$(grep '^PublishPort=' "$qf" | cut -d= -f2 | cut -d: -f1)
        local st
        if systemctl --user is-active --quiet "${sname}.service" 2>/dev/null; then
            st="${C_G}● ATIVO${NC}"
        else
            st="${C_R}○ PARADO${NC}"
        fi
        printf "  %-16s %-25s %-8s " "$sname" "${img:0:23}" "$port"
        echo -e "$st"
    done
    echo
    log_action "PODMAN_LIST" ""
}

cmd_podman_logs() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do serviço: " name; }
    [[ -z "$name" ]] && return

    if ! systemctl --user is-enabled --quiet "${name}.service" 2>/dev/null; then
        err "Serviço '${name}' não encontrado."
        return 1
    fi

    echo -e "\n  ${C_P}${C_B}📋 LOGS: ${name}${NC}\n"
    journalctl --user -u "${name}.service" --no-pager -n 50 2>/dev/null | sed 's/^/  /' || \
        warn "Sem logs disponíveis (journald pode estar desabilitado)"
    echo
}

cmd_podman_help() {
    echo -e "\n  ${C_P}${C_B}🐳 CROM Podman — Containers com Auto-Restart${NC}\n"
    echo -e "  ${C_C}crom-ws podman run${NC} <nome> <imagem> <porta>   Criar e iniciar container"
    echo -e "  ${C_C}crom-ws podman stop${NC} <nome>                   Parar container"
    echo -e "  ${C_C}crom-ws podman start${NC} <nome>                  Reiniciar container"
    echo -e "  ${C_C}crom-ws podman rm${NC} <nome>                     Remover container"
    echo -e "  ${C_C}crom-ws podman list${NC}                          Listar containers"
    echo -e "  ${C_C}crom-ws podman logs${NC} <nome>                   Ver logs\n"
    echo -e "  ${C_D}Containers criados aqui reiniciam automaticamente no boot da VPS.${NC}"
    echo -e "  ${C_D}Para expor na web: crom-ws publish <nome> <porta>${NC}\n"
}
