# 🛠️ CROM Workspace

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)]()
[![Shell](https://img.shields.io/badge/shell-bash-green.svg)]()

> **Sistema de workspace isolado para comunidades.** Gerencie membros, projetos e auditoria em servidores compartilhados com segurança e transparência.

---

## O que é

O CROM Workspace é um conjunto de ferramentas de linha de comando projetado para **comunidades que compartilham servidores**. Ele fornece:

- **`crom-ws`** — CLI para membros criarem e gerenciarem projetos pessoais
- **`crom-monitor`** — Painel administrativo para monitorar atividade dos membros
- **Sistema de auditoria** — Registro automático de todos os comandos e sessões

Cada membro tem seu espaço isolado, com projetos organizados e publicação web integrada.

---

## Instalação

> Executar como **root** no servidor.

```bash
git clone https://github.com/MrJc01/crom-workspace.git
cd crom-workspace
sudo bash install.sh
```

O instalador configura:
1. `crom-ws` disponível globalmente para todos os membros
2. `crom-monitor` para administradores
3. Logging de comandos bash (auditoria)
4. Gravação de sessões de terminal
5. Process accounting (`acct`)

---

## Uso — Membro

Após login via SSH, qualquer membro pode usar:

```bash
crom-ws help                    # Ver todos os comandos
```

### Comandos

| Comando | Descrição |
|---------|-----------|
| `crom-ws init [nome]` | Criar projeto com estrutura padronizada |
| `crom-ws list` | Listar todos os seus projetos |
| `crom-ws info [projeto]` | Ver detalhes de um projeto / workspace |
| `crom-ws delete [nome]` | Deletar projeto (pede confirmação) |
| `crom-ws publish [nome] [porta]` | Publicar projeto na web via subdomínio |
| `crom-ws unpublish [nome]` | Remover publicação |
| `crom-ws ports` | Ver portas em uso no servidor |
| `crom-ws status` | Status geral do workspace |
| `crom-ws history [n]` | Últimas ações executadas |

### Exemplo

```bash
$ crom-ws init api-rest
  Descrição: API REST do meu projeto
  Stack (go/python/web): go
  ✓ Projeto 'api-rest' criado em ~/projetos/api-rest

$ crom-ws list
  📁 MEUS PROJETOS

  PROJETO            STACK      DESCRIÇÃO                      CRIADO
  api-rest           go         API REST do meu projeto        2026-05-06

$ crom-ws publish api-rest 8080
  ✓ Projeto publicado com sucesso!
  ✓ URL: http://api-rest-user.example.com
```

---

## Uso — Administrador

```bash
crom-monitor                    # Menu interativo
```

### Funcionalidades

| Recurso | Descrição |
|---------|-----------|
| Atividade recente | Logs de todos os membros consolidados |
| Monitor ao vivo | `tail -f` em tempo real de todos os logs |
| Comandos bash | Ver cada comando digitado por um membro |
| Gravações | Replay de sessões completas de terminal |
| Projetos | Ver todos os projetos de todos os membros |
| Relatório | Resumo de membros, projetos, uso de disco |

---

## Estrutura de Projetos

Cada projeto criado segue esta estrutura:

```
~/projetos/meu-projeto/
├── src/               # Código fonte
├── docs/              # Documentação
├── scripts/           # Scripts auxiliares
├── README.md          # Descrição do projeto
└── .crom-project      # Metadados (owner, stack, data)
```

---

## Auditoria

O sistema registra **3 camadas** de atividade:

| Camada | O que captura | Localização |
|--------|---------------|-------------|
| **Comandos bash** | Cada comando digitado | `/var/log/crom-membros/bash/` |
| **Sessões** | Terminal inteiro gravado | `/var/log/crom-membros/sessions/` |
| **Ações crom-ws** | Criação/deleção de projetos | `/var/log/crom-membros/<user>.log` |

Administradores acessam tudo via `crom-monitor`.

---

## Adaptando para Sua Comunidade

O CROM Workspace é genérico. Para usar na sua comunidade:

1. Clone este repo no servidor
2. Rode `install.sh` como root
3. Crie membros com `useradd` e adicione ao grupo `crom-membros`
4. Cada membro faz SSH e usa `crom-ws`

O sistema funciona com qualquer domínio e pode ser integrado com Nginx para publicação de projetos.

---

## Licença

[MIT](LICENSE) — Use, modifique e distribua livremente.

---

> Desenvolvido pelo [Coletivo CROM](https://crom.run) 🛡️
