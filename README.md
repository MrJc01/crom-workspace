# 🛠️ CROM Workspace (crom-ws)

> CLI oficial para membros do ecossistema CROM gerenciarem projetos, containers e publicação web nas VPS da comunidade.

**Versão:** 1.1.0

---

## O que é

O `crom-ws` é uma ferramenta de linha de comando instalada em todas as VPS do [Coletivo CROM](https://crom.run). Ele permite que cada membro:

- 📁 **Crie e organize projetos** com estrutura padronizada
- 🌐 **Publique na web** com subdomínio e HTTPS automático (Let's Encrypt)
- 🐳 **Rode containers Podman** com auto-restart nativo via Quadlets
- 📊 **Monitore** uso de disco, portas e histórico de ações

## Infraestrutura

| VPS | Domínio | Propósito |
|-----|---------|-----------|
| Guardiões | `crom.me` | VPS principal — serviços core |
| Pilares | `vps1.crom.me` | Membros classificados como Pilar |
| Forja | `vps2.crom.me` | Membros classificados como Forja |

## Comandos

### Projetos
```bash
crom-ws init meu-projeto        # Criar projeto
crom-ws list                    # Listar projetos
crom-ws info meu-projeto        # Ver detalhes
crom-ws delete meu-projeto      # Deletar projeto
```

### Publicação Web
```bash
crom-ws publish meu-projeto 8080  # Publicar com HTTPS automático
crom-ws unpublish meu-projeto     # Remover da web
crom-ws ports                     # Ver portas em uso no servidor
```

### Containers (Podman)
```bash
crom-ws podman run meu-redis redis:alpine 6379  # Criar com auto-restart
crom-ws podman list                              # Listar containers
crom-ws podman stop meu-redis                    # Parar
crom-ws podman start meu-redis                   # Iniciar
crom-ws podman rm meu-redis                      # Remover
crom-ws podman logs meu-redis                    # Ver logs
```

### Sistema
```bash
crom-ws status                  # Status do workspace
crom-ws history                 # Histórico de ações
crom-ws help                    # Ajuda completa
```

## Arquitetura

```
cli/
├── crom-ws                  # Entry point principal
├── crom-publish-helper      # Helper de proxy Nginx (executado como root)
└── modules/
    ├── projects.sh          # init, list, info, delete
    ├── publish.sh           # publish, unpublish, ports
    └── podman.sh            # podman run/stop/start/rm/list/logs

docs/
├── documentacao.md          # Documentação completa
├── guia-membros.md          # Guia de onboarding
└── politica-acesso.md       # Política de uso

monitor/
└── crom-monitor.sh          # Painel admin (somente root)

install.sh                   # Instalador completo
```

## Como funciona o auto-restart (Podman Quadlets)

Quando você executa `crom-ws podman run`, o sistema:

1. Cria um arquivo **Quadlet** em `~/.config/containers/systemd/`
2. Roda `systemctl --user daemon-reload`
3. Habilita e inicia o serviço com `systemctl --user enable --now`

O **Linger** do systemd garante que os serviços do usuário continuam rodando mesmo após logout e sobrevivem a reboots da VPS.

## Documentação

- 📘 [Documentação Completa](docs/documentacao.md)
- 📖 [Guia do Membro](docs/guia-membros.md)
- 🛡️ [Política de Acesso](docs/politica-acesso.md)

## Ecossistema CROM

| Recurso | URL |
|---------|-----|
| Portal | [crom.run](https://crom.run) |
| GitHub | [github.com/MrJc01](https://github.com/MrJc01) |
| Discord | [discord.gg/4b5wqdxreZ](https://discord.gg/4b5wqdxreZ) |
| Wiki | [crom-wiki](https://github.com/MrJc01/crom-wiki) |

## Licença

MIT — Coletivo CROM
