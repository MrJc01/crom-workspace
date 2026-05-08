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
        compose) cmd_podman_compose "$@" ;;
        help|-h) cmd_podman_help ;;
        *)      err "Subcomando podman desconhecido: $sub"; cmd_podman_help ;;
    esac
}

cmd_podman_run() {
    local name=""
    local image=""
    local port=""
    local envs=()
    local volumes=()
    local extra_args=()
    local port_maps=()
    local container_name=""

    # Parser de flags no estilo Docker
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -e|--env)
                envs+=("$2"); shift 2 ;;
            -v|--volume)
                volumes+=("$2"); shift 2 ;;
            -p|--publish)
                port_maps+=("$2"); shift 2 ;;
            --name)
                container_name="$2"; shift 2 ;;
            --args)
                extra_args+=("$2"); shift 2 ;;
            -*)
                err "Flag desconhecida: $1"; cmd_podman_help; return 1 ;;
            *)
                # Argumentos posicionais: nome imagem [porta]
                if [[ -z "$name" ]]; then
                    name="$1"
                elif [[ -z "$image" ]]; then
                    image="$1"
                elif [[ -z "$port" ]]; then
                    port="$1"
                fi
                shift ;;
        esac
    done

    # Validações (interativo se necessário)
    [[ -z "$name" ]] && { read -rp "  Nome do serviço: " name; }
    [[ -z "$name" ]] && { err "Nome obrigatório"; return 1; }
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')

    [[ -z "$image" ]] && { read -rp "  Imagem (ex: redis:alpine, n8nio/n8n): " image; }
    [[ -z "$image" ]] && { err "Imagem obrigatória"; return 1; }

    # Porta é opcional se -p foi usado
    if [[ -z "$port" ]] && [[ ${#port_maps[@]} -eq 0 ]]; then
        read -rp "  Porta exposta (ex: 5678, ou enter para nenhuma): " port
    fi

    # Garantir diretório de Quadlets
    mkdir -p "$QUADLET_DIR"

    local quadlet_file="${QUADLET_DIR}/${name}.container"

    if [[ -f "$quadlet_file" ]]; then
        warn "Quadlet '${name}' já existe. Use 'crom-ws podman rm ${name}' primeiro."
        return 1
    fi

    info "Gerando Quadlet para '${name}'..."

    # Construir seção [Container]
    local container_section=""
    container_section+="Image=${image}\n"

    # Container name
    if [[ -n "$container_name" ]]; then
        container_section+="ContainerName=${container_name}\n"
    fi

    # Portas: -p tem prioridade, senão usa porta posicional
    if [[ ${#port_maps[@]} -gt 0 ]]; then
        for pm in "${port_maps[@]}"; do
            container_section+="PublishPort=${pm}\n"
        done
    elif [[ -n "$port" ]]; then
        container_section+="PublishPort=${port}:${port}\n"
    fi

    # Volumes: -v tem prioridade, senão cria volume padrão
    if [[ ${#volumes[@]} -gt 0 ]]; then
        for vol in "${volumes[@]}"; do
            # Expandir ~ para $HOME
            vol="${vol/#\~/$HOME}"
            container_section+="Volume=${vol}\n"
        done
    else
        local volume_dir="${HOME}/.local/share/crom-volumes/${name}"
        mkdir -p "$volume_dir"
        container_section+="Volume=${volume_dir}:/data:Z\n"
    fi

    # Variáveis de ambiente
    for env in "${envs[@]}"; do
        container_section+="Environment=${env}\n"
    done

    # Args extras do Podman
    for arg in "${extra_args[@]}"; do
        container_section+="PodmanArgs=${arg}\n"
    done

    container_section+="AutoUpdate=registry\n"
    container_section+="Label=crom.project=${name}\n"
    container_section+="Label=crom.owner=${USER_NAME}\n"
    [[ -n "$port" ]] && container_section+="Label=crom.port=${port}\n"

    # Escrever o Quadlet
    cat > "$quadlet_file" <<EOF
[Unit]
Description=CROM Container: ${name}
After=default.target

[Container]
$(echo -e "$container_section")
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
        [[ -n "$port" ]] && success "Porta: ${port}"
        [[ ${#envs[@]} -gt 0 ]] && success "Env vars: ${#envs[@]} configuradas"
        [[ ${#volumes[@]} -gt 0 ]] && success "Volumes: ${#volumes[@]} montados"
        success "Auto-restart: ATIVO (sobrevive reboot)"
        if [[ -n "$port" ]]; then
            echo -e "\n  ${C_D}Dica: Para publicar na web, rode:${NC}"
            echo -e "  ${C_C}crom-ws publish ${name} ${port}${NC}\n"
        fi
    else
        warn "Serviço criado, mas pode estar ainda baixando a imagem..."
        warn "Verifique com: crom-ws podman logs ${name}"
    fi

    log_action "PODMAN_RUN" "name=${name} image=${image} port=${port} envs=${#envs[@]} vols=${#volumes[@]}"
}

cmd_podman_compose() {
    local name="${1:-}"
    
    [[ -z "$name" ]] && { read -rp "  Nome do serviço compose: " name; }
    [[ -z "$name" ]] && { err "Nome obrigatório"; return 1; }
    name=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')

    if [[ ! -f "docker-compose.yml" ]] && [[ ! -f "docker-compose.yaml" ]] && [[ ! -f "compose.yml" ]] && [[ ! -f "compose.yaml" ]]; then
        err "Nenhum arquivo docker-compose.yml encontrado no diretório atual."
        return 1
    fi

    local compose_file=""
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
        if [[ -f "$f" ]]; then
            compose_file="$f"
            break
        fi
    done

    local workdir="$PWD"
    local systemd_dir="${HOME}/.config/systemd/user"
    local service_file="${systemd_dir}/${name}.service"

    mkdir -p "$systemd_dir"

    if [[ -f "$service_file" ]]; then
        warn "Serviço '${name}' já existe. Use 'crom-ws podman rm ${name}' primeiro."
        return 1
    fi

    info "Gerando serviço Systemd para Compose '${name}'..."

    local pc_path=$(which podman-compose 2>/dev/null || echo "/usr/bin/podman-compose")

    cat > "$service_file" <<EOF
[Unit]
Description=CROM Compose: ${name}
Requires=network-online.target
After=network-online.target

[Service]
Type=exec
WorkingDirectory=${workdir}
ExecStart=${pc_path} -f ${compose_file} up
ExecStop=${pc_path} -f ${compose_file} down
Restart=always
RestartSec=10
TimeoutStopSec=60

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
        success "Compose '${name}' está rodando!"
        success "Diretório: ${workdir}"
        success "Auto-restart: ATIVO (sobrevive reboot)"
        echo -e "\n  ${C_D}Dica: Para parar, use: crom-ws podman stop ${name}${NC}\n"
    else
        warn "Serviço criado, mas pode ter falhado. Verifique com: crom-ws podman logs ${name}"
    fi

    log_action "PODMAN_COMPOSE" "name=${name} dir=${workdir}"
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
    local compose_file="${HOME}/.config/systemd/user/${name}.service"
    if [[ ! -f "$quadlet_file" ]] && [[ ! -f "$compose_file" ]]; then
        err "Serviço '${name}' não encontrado."
        return 1
    fi

    # Parar e desabilitar
    systemctl --user stop "${name}.service" 2>/dev/null || true
    systemctl --user disable "${name}.service" 2>/dev/null || true

    # Remover arquivo
    rm -f "$quadlet_file" "$compose_file"
    systemctl --user daemon-reload

    success "Container '${name}' removido do sistema."
    info "Os dados e volumes permanecem no disco."
    log_action "PODMAN_RM" "name=${name}"
}

cmd_podman_list() {
    echo -e "\n  ${C_P}${C_B}🐳 CONTAINERS GERENCIADOS (Quadlets / Compose)${NC}\n"

    local found=0
    if [[ -d "$QUADLET_DIR" ]] && [[ -n "$(ls -A "$QUADLET_DIR"/*.container 2>/dev/null)" ]]; then
        found=1
    fi
    if [[ -d "${HOME}/.config/systemd/user" ]] && grep -q "CROM Compose:" "${HOME}/.config/systemd/user"/*.service 2>/dev/null; then
        found=1
    fi

    if [[ $found -eq 0 ]]; then
        info "Nenhum container gerenciado."
        info "Use: crom-ws podman run <nome> <imagem> [porta]"
        info "Ou: crom-ws podman compose <nome>"
        echo
        return
    fi

    printf "  ${C_B}%-16s %-25s %-8s %-12s${NC}\n" "SERVIÇO" "TIPO/IMAGEM" "PORTA" "STATUS"
    
    # Quadlets
    if [[ -d "$QUADLET_DIR" ]]; then
        for qf in "$QUADLET_DIR"/*.container; do
            [[ -f "$qf" ]] || continue
            local sname=$(basename "$qf" .container)
            local img=$(grep '^Image=' "$qf" | cut -d= -f2)
            local port=$(grep '^PublishPort=' "$qf" | head -1 | cut -d= -f2 | cut -d: -f1)
            local st
            if systemctl --user is-active --quiet "${sname}.service" 2>/dev/null; then
                st="${C_G}● ATIVO${NC}"
            else
                st="${C_R}○ PARADO${NC}"
            fi
            printf "  %-16s %-25s %-8s " "$sname" "${img:0:23}" "${port:--}"
            echo -e "$st"
        done
    fi

    # Composes
    if [[ -d "${HOME}/.config/systemd/user" ]]; then
        for cf in "${HOME}/.config/systemd/user"/*.service; do
            [[ -f "$cf" ]] || continue
            if grep -q "CROM Compose:" "$cf"; then
                local sname=$(basename "$cf" .service)
                local st
                if systemctl --user is-active --quiet "${sname}.service" 2>/dev/null; then
                    st="${C_G}● ATIVO${NC}"
                else
                    st="${C_R}○ PARADO${NC}"
                fi
                printf "  %-16s %-25s %-8s " "$sname" "docker-compose" "-"
                echo -e "$st"
            fi
        done
    fi
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
    echo -e "  ${C_B}Uso básico:${NC}"
    echo -e "  ${C_C}crom-ws podman run${NC} <nome> <imagem> [porta]         Criar container simples"
    echo -e "  ${C_C}crom-ws podman compose${NC} <nome>                      Criar serviço via docker-compose.yml\n"
    echo -e "  ${C_B}Uso avançado (flags no estilo Docker):${NC}"
    echo -e "  ${C_C}-e${NC} KEY=VALUE          Variável de ambiente (pode repetir)"
    echo -e "  ${C_C}-v${NC} /host:/container   Volume customizado (pode repetir)"
    echo -e "  ${C_C}-p${NC} HOST:CONTAINER     Mapeamento de porta (pode repetir)"
    echo -e "  ${C_C}--name${NC} NOME           Nome do container interno"
    echo -e "  ${C_C}--args${NC} \"FLAGS\"         Args extras do Podman (ex: --pod=meu-pod)\n"
    echo -e "  ${C_B}Exemplos:${NC}"
    echo -e "  ${C_D}# Simples — Redis na porta 6379${NC}"
    echo -e "  ${C_C}crom-ws podman run${NC} meu-redis redis:alpine 6379\n"
    echo -e "  ${C_D}# Avançado — n8n com env vars e volume custom${NC}"
    echo -e "  ${C_C}crom-ws podman run${NC} n8n n8nio/n8n 5678 \\"
    echo -e "    -e WEBHOOK_URL=https://n8n.vps1.crom.me/ \\"
    echo -e "    -e N8N_SECURE_COOKIE=true \\"
    echo -e "    -v ~/n8n/data:/home/node/.n8n:Z\n"
    echo -e "  ${C_D}# Com pod e porta customizada${NC}"
    echo -e "  ${C_C}crom-ws podman run${NC} meu-app minha-imagem \\"
    echo -e "    -p 8080:80 --args \"--pod=meu-pod\"\n"
    echo -e "  ${C_B}Gerenciamento:${NC}"
    echo -e "  ${C_C}crom-ws podman stop${NC} <nome>       Parar container"
    echo -e "  ${C_C}crom-ws podman start${NC} <nome>      Reiniciar container"
    echo -e "  ${C_C}crom-ws podman rm${NC} <nome>         Remover container"
    echo -e "  ${C_C}crom-ws podman list${NC}              Listar containers"
    echo -e "  ${C_C}crom-ws podman logs${NC} <nome>       Ver logs\n"
    echo -e "  ${C_D}Containers criados aqui reiniciam automaticamente no boot da VPS.${NC}"
    echo -e "  ${C_D}Para expor na web: crom-ws publish <nome> <porta>${NC}\n"
}

