#!/usr/bin/env bash
# CROM Workspace — Instalador no VPS
# Configura: crom-ws, logging de bash, gravação de sessão, auditoria
# Executar como root no VPS de membros
set -euo pipefail

[[ "$(id -u)" -ne 0 ]] && { echo "Execute como root!"; exit 1; }

LOG_DIR="/var/log/crom-membros"
BASH_LOG_DIR="${LOG_DIR}/bash"
SESSION_DIR="${LOG_DIR}/sessions"
REG_DIR="${LOG_DIR}/registry"

echo "=== CROM Workspace Installer ==="
echo ""

# 1. Criar diretórios de log
echo "[1/5] Criando diretórios de log..."
mkdir -p "$LOG_DIR" "$BASH_LOG_DIR" "$SESSION_DIR" "$REG_DIR"
chmod 733 "$LOG_DIR"        # membros podem escrever, não ler outros
chmod 733 "$BASH_LOG_DIR"
chmod 733 "$SESSION_DIR"
chmod 733 "$REG_DIR"

# 2. Instalar crom-ws globalmente
echo "[2/5] Instalando crom-ws em /usr/local/bin..."
cp crom-ws /usr/local/bin/crom-ws
chmod 755 /usr/local/bin/crom-ws

# 3. Instalar crom-monitor
echo "[3/5] Instalando crom-monitor em /usr/local/bin..."
cp crom-monitor.sh /usr/local/bin/crom-monitor
chmod 755 /usr/local/bin/crom-monitor

# 4. Configurar logging global de bash
echo "[4/5] Configurando logging de comandos..."
cat > /etc/profile.d/crom-audit.sh <<'AUDIT'
# CROM Audit — Loga todos os comandos dos membros
if [[ "$(id -u)" -ne 0 ]]; then
    _CROM_USER="$(whoami)"
    _CROM_BASH_LOG="/var/log/crom-membros/bash/${_CROM_USER}_commands.log"
    _CROM_SESSION_DIR="/var/log/crom-membros/sessions"

    # Timestamps no history
    export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S  "
    export HISTSIZE=10000
    export HISTFILESIZE=20000

    # Logar cada comando via PROMPT_COMMAND
    _crom_log_cmd() {
        local cmd=$(history 1 | sed 's/^ *[0-9]* *//')
        if [[ -n "$cmd" && "$cmd" != "$_CROM_LAST_CMD" ]]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${_CROM_USER}: ${cmd}" >> "$_CROM_BASH_LOG" 2>/dev/null
            _CROM_LAST_CMD="$cmd"
        fi
    }
    _CROM_LAST_CMD=""
    PROMPT_COMMAND="_crom_log_cmd;${PROMPT_COMMAND:-}"

    # Gravação de sessão (se script disponível)
    if [[ -z "${CROM_SESSION_ACTIVE:-}" ]] && command -v script &>/dev/null; then
        export CROM_SESSION_ACTIVE=1
        _sess_file="${_CROM_SESSION_DIR}/${_CROM_USER}_$(date +%Y%m%d_%H%M%S).log"
        exec script -q -a "$_sess_file" 2>/dev/null
    fi
fi
AUDIT
chmod 644 /etc/profile.d/crom-audit.sh

# 5. Instalar acct para process accounting
echo "[5/5] Instalando process accounting..."
if ! command -v lastcomm &>/dev/null; then
    apt-get install -y acct >/dev/null 2>&1 || true
fi
systemctl enable acct 2>/dev/null || true
systemctl start acct 2>/dev/null || true

# 6. Criar grupo crom-membros se não existe
getent group crom-membros >/dev/null 2>&1 || groupadd crom-membros

echo ""
echo "=== INSTALAÇÃO CONCLUÍDA ==="
echo ""
echo "Para membros:  crom-ws help"
echo "Para admin:    crom-monitor"
echo ""
echo "Logs em:       ${LOG_DIR}/"
echo "Bash logs:     ${BASH_LOG_DIR}/"
echo "Sessões:       ${SESSION_DIR}/"
echo "Registros:     ${REG_DIR}/"
