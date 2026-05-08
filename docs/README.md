# 📚 Documentação — CROM Workspace

Documentação completa do `crom-ws`, a CLI do ecossistema [Coletivo CROM](https://crom.run).

---

## 📖 Índice

| Documento | Descrição | Para quem? |
|-----------|-----------|------------|
| [**documentacao.md**](documentacao.md) | Referência técnica completa de todos os comandos, flags, exemplos de uso, estrutura de arquivos e sistema de auditoria | Membros que querem entender cada detalhe |
| [**guia-membros.md**](guia-membros.md) | Guia de onboarding — como acessar a VPS via SSH, criar projetos, publicar na web e rodar containers | Novos membros (leia primeiro!) |
| [**politica-acesso.md**](politica-acesso.md) | Regras de uso, classificação de membros, proibições, penalidades e política de privacidade | Todos os membros |

---

## 🚀 Começando rápido

Se você acabou de receber sua conta, siga esta ordem:

1. **Leia o [Guia do Membro](guia-membros.md)** — explica como conectar via SSH e os primeiros passos
2. **Consulte a [Documentação Completa](documentacao.md)** — referência de todos os comandos disponíveis
3. **Aceite a [Política de Acesso](politica-acesso.md)** — regras de convivência no servidor

---

## 🛠️ Comandos rápidos

```bash
# Criar um projeto
crom-ws init meu-site

# Publicar na web (HTTPS automático)
crom-ws publish meu-site 3000

# Criar um container com auto-restart
crom-ws podman run meu-banco postgres:16-alpine 5432

# Ver tudo que está rodando
crom-ws podman list
crom-ws ports

# Ajuda completa
crom-ws help
crom-ws podman help
```

---

## 🏗️ Arquitetura do crom-ws

```
crom-workspace/
├── cli/                         # Código-fonte da CLI
│   ├── crom-ws                  # Entry point (carrega módulos)
│   ├── crom-publish-helper      # Helper Nginx (executado via sudo)
│   └── modules/                 # Módulos separados por domínio
│       ├── projects.sh          # Gestão de projetos
│       ├── publish.sh           # Publicação web + Nginx
│       └── podman.sh            # Containers + Quadlets
│
├── docs/                        # ← Você está aqui
│   ├── README.md                # Este índice
│   ├── documentacao.md          # Referência técnica completa
│   ├── guia-membros.md          # Onboarding de novos membros
│   └── politica-acesso.md       # Regras e políticas
│
├── monitor/
│   └── crom-monitor.sh          # Painel admin (somente root)
│
├── install.sh                   # Instalador automático
├── LICENSE                      # MIT
└── README.md                    # Visão geral do projeto
```

---

## 🆘 Suporte

Problemas, dúvidas ou sugestões? Entre em contato:

- **Discord:** [discord.gg/4b5wqdxreZ](https://discord.gg/4b5wqdxreZ)
- **GitHub Issues:** [crom-workspace/issues](https://github.com/MrJc01/crom-workspace/issues)
- **Administrador:** MRJ
