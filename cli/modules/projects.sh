#!/usr/bin/env bash
# CROM Workspace — Módulo de Projetos
# Comandos: init, list, info, delete

cmd_init() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Nome do projeto: " name; }
    [[ -z "$name" ]] && { err "Nome obrigatório"; return 1; }
    name=$(echo "$name" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9_-]//g')
    local pdir="${PROJECTS_DIR}/${name}"
    [[ -d "$pdir" ]] && { err "'${name}' já existe!"; return 1; }
    read -rp "  Descrição: " desc; desc="${desc:-Sem descrição}"
    read -rp "  Stack (go/python/web): " stack; stack="${stack:-geral}"
    mkdir -p "${pdir}/src" "${pdir}/docs" "${pdir}/scripts"
    cat > "${pdir}/.crom-project" <<EOF
name=${name}
owner=${USER_NAME}
description=${desc}
stack=${stack}
created=$(date -u +%Y-%m-%dT%H:%M:%SZ)
status=ativo
EOF
    echo "# ${name}" > "${pdir}/README.md"
    echo "" >> "${pdir}/README.md"
    echo "> ${desc}" >> "${pdir}/README.md"
    echo "${name}|${desc}|${stack}|$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "${CENTRAL_REG}/projects.list" 2>/dev/null || true
    log_action "CREATE_PROJECT" "name=${name} stack=${stack}"
    success "Projeto '${name}' criado em ${pdir}"
}

cmd_list() {
    echo -e "\n  ${C_P}${C_B}📁 MEUS PROJETOS${NC}\n"
    if [[ ! -d "$PROJECTS_DIR" ]] || [[ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null)" ]]; then
        warn "Nenhum projeto. Use: crom-ws init <nome>"; return; fi
    printf "  ${C_B}%-18s %-10s %-30s %-12s${NC}\n" "PROJETO" "STACK" "DESCRIÇÃO" "CRIADO"
    for dir in "$PROJECTS_DIR"/*/; do
        [[ ! -d "$dir" ]] && continue
        local m="${dir}.crom-project" n s d c
        if [[ -f "$m" ]]; then
            n=$(grep '^name=' "$m" | cut -d= -f2)
            s=$(grep '^stack=' "$m" | cut -d= -f2)
            d=$(grep '^description=' "$m" | cut -d= -f2)
            c=$(grep '^created=' "$m" | cut -d= -f2 | cut -dT -f1)
        else n=$(basename "$dir"); s="-"; d="-"; c="-"; fi
        printf "  %-18s %-10s %-30s %-12s\n" "$n" "$s" "${d:0:28}" "$c"
    done
    echo; log_action "LIST_PROJECTS" ""
}

cmd_info() {
    local name="${1:-}"
    if [[ -z "$name" ]]; then
        echo -e "\n  ${C_P}${C_B}ℹ️  WORKSPACE${NC}\n"
        echo -e "  User:     ${USER_NAME}"
        echo -e "  Home:     ${HOME}"
        echo -e "  Projetos: $(find "$PROJECTS_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)"
        echo -e "  Disco:    $(du -sh "$HOME" 2>/dev/null | awk '{print $1}')"
        echo -e "  Versão:   ${VERSION}"; echo; return; fi
    local pdir="${PROJECTS_DIR}/${name}"
    [[ ! -d "$pdir" ]] && { err "'${name}' não encontrado"; return 1; }
    echo -e "\n  ${C_P}${C_B}📋 ${name}${NC}\n"
    [[ -f "${pdir}/.crom-project" ]] && sed 's/^/  /' "${pdir}/.crom-project"
    echo -e "  disco=$(du -sh "$pdir" 2>/dev/null | awk '{print $1}')"
    echo -e "  arquivos=$(find "$pdir" -type f | wc -l)"; echo
    log_action "VIEW_PROJECT" "name=${name}"
}

cmd_delete() {
    local name="${1:-}"
    [[ -z "$name" ]] && { read -rp "  Projeto para deletar: " name; }
    [[ -z "$name" ]] && return
    local pdir="${PROJECTS_DIR}/${name}"
    [[ ! -d "$pdir" ]] && { err "'${name}' não encontrado"; return 1; }
    read -rp "  Digite '${name}' para confirmar: " conf
    [[ "$conf" != "$name" ]] && { info "Cancelado"; return; }
    rm -rf "$pdir"
    log_action "DELETE_PROJECT" "name=${name}"
    success "'${name}' deletado"
}
