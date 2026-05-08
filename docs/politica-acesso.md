# 🛡️ Política de Acesso — Ecossistema Multi-VPS CROM

**Atualizado em**: 2026-05-08
**Versão**: 3.0

---

## 1. Elegibilidade

- Membros ativos da comunidade CROM
- Aprovação e classificação pelo administrador (MRJ)
- Aceitar os termos de uso e esta política

## 2. Classificação de Membros

Ao ingressar, cada membro é classificado em uma de duas categorias:

| Categoria | VPS | Descrição |
|-----------|-----|-----------|
| **Pilar** | `vps1.crom.me` | Membros com papel estrutural no coletivo |
| **Forja** | `vps2.crom.me` | Membros em fase de desenvolvimento e aprendizado |

> A VPS Guardiões (`crom.me`) hospeda os serviços core do ecossistema (CromIA, landing page, etc).

## 3. Tipos de Acesso

| Nível | Shell | Descrição |
|-------|-------|-----------|
| **Membro Ativo** | `/bin/bash` | Acesso SSH completo à área pessoal |
| **Restrito** | `/usr/sbin/nologin` | Sem acesso SSH (apenas serviços) |
| **Banido** | Conta bloqueada | Acesso revogado temporária ou permanentemente |

## 4. Recursos por Membro

- **Diretório home** pessoal e isolado em `/home/username/`
- **Ferramenta `crom-ws`** para gerenciar projetos, publicar na web e rodar containers
- **Podman** (Docker rootless) para containers sem precisar de root
- **Auto-restart de containers** via Quadlets do Systemd (sobrevive reboots)
- **Publicação web** com subdomínio e HTTPS automático (Let's Encrypt)
- **Crontab** pessoal para agendar tarefas
- **Git** disponível para versionamento
- **Sem acesso root** — operações privilegiadas somente via admin (MRJ)

## 5. Proibições

- Mineração de criptomoedas
- Hospedagem de conteúdo ilegal
- Port scanning ou ataques a terceiros
- Tentativa de escalar privilégios
- Uso excessivo de recursos (CPU/RAM/Disco) sem autorização
- Acessar diretórios de outros membros

## 6. Comunicação e Portas

Antes de subir um serviço em uma porta, o membro **deve comunicar** aos demais membros da mesma VPS para evitar conflitos. Use o comando `crom-ws ports` para verificar o que já está em uso.

## 7. Penalidades

| Infração | Ação |
|----------|------|
| 1ª Ocorrência leve | Aviso formal |
| 2ª Ocorrência leve | Suspensão temporária (ban reversível) |
| Ocorrência grave | Ban permanente + deleção da conta |

## 8. Monitoramento e Privacidade

A filosofia do CROM é **Liberdade com Responsabilidade**:

- ✅ Acessos SSH são logados automaticamente (horário, IP, duração)
- ✅ Comandos executados no terminal são registrados para auditoria
- ✅ Relatórios periódicos são gerados via orquestrador
- ✅ O administrador pode verificar sessões ativas a qualquer momento

**O que NÃO fazemos:**

- ❌ Não lemos seus arquivos pessoais sem motivo
- ❌ Não monitoramos ativamente o que você faz em tempo real
- ❌ Não acessamos logs sem necessidade de auditoria

> Os logs existem para **proteção de todos** — só serão consultados em caso de incidente de segurança, denúncia ou comportamento suspeito no sistema.

## 9. Solicitação de Conta

Para obter acesso, entre em contato com o administrador **MRJ** pelo Discord do Coletivo CROM. Ele realizará a avaliação, classificará o membro (Pilar ou Forja) e criará a conta na VPS apropriada.

## 10. Alterações

Esta política pode ser atualizada a qualquer momento. Membros serão notificados de mudanças significativas pelo Discord.
