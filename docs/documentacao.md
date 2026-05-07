# 📘 Documentação — CROM Workspace (crom-ws)

> Ferramenta de linha de comando para membros CROM gerenciarem seus projetos no servidor.
> Versão: 1.0.0

---

## O que é

O `crom-ws` é uma CLI (Command Line Interface) instalada em todas as VPS do ecossistema CROM. Ele permite que cada membro crie, organize e gerencie projetos pessoais dentro do seu espaço no servidor.

**Infraestrutura disponível:**

| VPS | Domínio | Propósito |
|-----|---------|-----------|
| Guardiões | `crom.me` | VPS principal — serviços core |
| Pilares | `vps1.crom.me` | VPS de membros Pilar |
| Forja | `vps2.crom.me` | VPS de membros Forja |

> ℹ️ O `crom-ws` funciona de forma idêntica em todas as VPS. Ao conectar via SSH, o membro já terá acesso ao `crom-ws` na VPS onde sua conta foi criada.

**Características:**
- Cada membro tem seu próprio workspace isolado
- Projetos são organizados em `~/projetos/`
- Cada ação é **registrada automaticamente** para auditoria
- Interface colorida e intuitiva no terminal

---

## Instalação

O `crom-ws` já vem **pré-instalado** no servidor. Qualquer membro pode usá-lo assim que fizer login via SSH.

Se precisar reinstalar (como root):
```bash
cp crom-ws /usr/local/bin/crom-ws
chmod 755 /usr/local/bin/crom-ws
```

---

## Comandos

### `crom-ws init [nome]` — Criar projeto

Cria um novo projeto com estrutura padronizada.

```bash
crom-ws init meu-site
```

**O que acontece:**
1. Pergunta nome, descrição e stack (se não informados)
2. Cria a pasta `~/projetos/meu-site/` com subdiretórios:
   ```
   meu-site/
   ├── src/            # Código fonte
   ├── docs/           # Documentação
   ├── scripts/        # Scripts auxiliares
   ├── README.md       # Descrição do projeto
   └── .crom-project   # Metadados (nome, owner, stack, data)
   ```
3. Registra o projeto no log central (admin pode ver)
4. Loga a ação: `CREATE_PROJECT`

**Exemplo interativo:**
```
$ crom-ws init
  Nome do projeto: api-crom
  Descrição: API REST para o ecossistema
  Stack (go/python/web): go
  ✓ Projeto 'api-crom' criado em /home/pedrodev/projetos/api-crom
```

**Exemplo direto:**
```bash
crom-ws init api-crom
```

---

### `crom-ws list` — Listar projetos

Mostra todos os projetos do membro com nome, stack, descrição e data.

```bash
crom-ws list
```

**Saída:**
```
  📁 MEUS PROJETOS

  PROJETO            STACK      DESCRIÇÃO                      CRIADO
  api-crom           go         API REST para o ecossistema    2026-05-01
  meu-site           web        Site pessoal                   2026-05-01

  ℹ  Total: 2 projeto(s)
```

**Aliases:** `crom-ws ls`

---

### `crom-ws info [projeto]` — Ver detalhes

Sem argumento, mostra informações do workspace:

```bash
crom-ws info
```
```
  ℹ️  WORKSPACE

  User:     pedrodev
  Home:     /home/pedrodev
  Projetos: 2
  Disco:    156K
  Versão:   1.0.0
```

Com nome do projeto, mostra detalhes do projeto:

```bash
crom-ws info api-crom
```
```
  📋 api-crom

  name=api-crom
  owner=pedrodev
  description=API REST para o ecossistema
  stack=go
  created=2026-05-01T12:00:00Z
  status=ativo
  disco=4.0K
  arquivos=3
```

**Aliases:** `crom-ws show`

---

### `crom-ws delete [projeto]` — Deletar projeto

Remove um projeto permanentemente. Pede confirmação digitando o nome.

```bash
crom-ws delete api-crom
```
```
  Digite 'api-crom' para confirmar: api-crom
  ✓ 'api-crom' deletado
```

**Aliases:** `crom-ws rm`

> ⚠️ **Atenção:** Isso deleta todos os arquivos do projeto. Não tem desfazer.

### `crom-ws publish [projeto] [porta]` — Publicar na web

Expõe o seu projeto local (rodando numa porta) para a internet através de um subdomínio oficial.

```bash
crom-ws publish api-crom 8080
```
```
  ℹ  Solicitando publicação para api-crom na porta 8080...
  ✓  Projeto publicado com sucesso!
  ✓  URL: http://api-crom-pedrodev.vps1.crom.me
```

> ℹ️ **O subdomínio gerado depende da VPS onde você está:**
> - Na VPS Guardiões: `api-crom-pedrodev.crom.me`
> - Na VPS Pilares: `api-crom-pedrodev.vps1.crom.me`
> - Na VPS Forja: `api-crom-pedrodev.vps2.crom.me`

> ⚠️ **Nota:** Você precisa estar rodando o seu app na porta `8080` (seja via npm, go, python, ou podman) para o site abrir.

---

### `crom-ws unpublish [projeto]` — Remover da web

Derruba o acesso público ao seu projeto imediatamente.

```bash
crom-ws unpublish api-crom
```

---

### `crom-ws ports` — Ver rede do ecossistema

Lista todas as portas em uso no servidor e os respectivos subdomínios, útil para saber qual porta está livre antes de publicar.

```bash
crom-ws ports
```
```
  🌐 PROJETOS PUBLICADOS (ECOSSISTEMA)

  PORTA    USUÁRIO         PROJETO         URL (DOMÍNIO)                      
  8080     pedrodev        api-crom        api-crom-pedrodev.vps1.crom.me             
```

---

### `crom-ws status` — Status do workspace

Mostra um painel resumido do workspace.

```bash
crom-ws status
```
```
  📊 STATUS

  ╔════════════════════════════════╗
  ║  User:     pedrodev            ║
  ║  Projetos: 2                   ║
  ║  Disco:    156K                ║
  ║  Versão:   1.0.0               ║
  ╚════════════════════════════════╝
```

**Aliases:** `crom-ws st`

---

### `crom-ws history [n]` — Histórico de ações

Mostra as últimas ações executadas (padrão: 20).

```bash
crom-ws history      # últimas 20
crom-ws history 5    # últimas 5
```
```
  📜 HISTÓRICO

  [2026-05-01 12:00:00] USER=pedrodev ACTION=INIT DETAILS="Workspace inicializado"
  [2026-05-01 12:01:00] USER=pedrodev ACTION=CREATE_PROJECT DETAILS="name=api-crom stack=go"
  [2026-05-01 12:05:00] USER=pedrodev ACTION=LIST_PROJECTS DETAILS=""
```

**Aliases:** `crom-ws log`

---

### `crom-ws help` — Ajuda

Mostra a referência rápida de todos os comandos.

```bash
crom-ws help
```

### `crom-ws version` — Versão

```bash
crom-ws version
# crom-ws v1.0.0
```

---

## Estrutura de arquivos

### No home do membro
```
~/
├── projetos/                    # Todos os projetos
│   ├── meu-site/
│   │   ├── src/
│   │   ├── docs/
│   │   ├── scripts/
│   │   ├── README.md
│   │   └── .crom-project        # Metadados do projeto
│   └── api-crom/
│       └── ...
│
└── .crom/                       # Configuração do workspace
    ├── config                   # User, data de criação
    └── history.log              # Histórico local de ações
```

### Logs centrais (somente admin vê)
```
/var/log/crom-membros/
├── pedrodev.log                 # Ações do crom-ws
├── bash/
│   └── pedrodev_commands.log    # Todos os comandos bash
├── sessions/
│   └── pedrodev_20260501.log    # Gravação do terminal
└── registry/
    └── pedrodev/
        └── projects.list        # Lista de projetos
```

---

## Sistema de auditoria

Toda ação no `crom-ws` gera um registro em **dois lugares**:

1. **Log local** (`~/.crom/history.log`) — o membro pode ver com `crom-ws history`
2. **Log central** (`/var/log/crom-membros/<user>.log`) — somente o admin (root) pode ver

### Ações registradas

| Ação | Quando |
|------|--------|
| `INIT` | Primeiro uso do crom-ws |
| `CREATE_PROJECT` | `crom-ws init` |
| `LIST_PROJECTS` | `crom-ws list` |
| `VIEW_PROJECT` | `crom-ws info <projeto>` |
| `VIEW_INFO` | `crom-ws info` (sem argumento) |
| `VIEW_STATUS` | `crom-ws status` |
| `DELETE_PROJECT` | `crom-ws delete` |
| `PUBLISH_PROJECT` | `crom-ws publish` |
| `UNPUBLISH_PROJECT` | `crom-ws unpublish` |
| `VIEW_PORTS` | `crom-ws ports` |

### Formato do log
```
[YYYY-MM-DD HH:MM:SS] USER=<username> ACTION=<ação> DETAILS="<detalhes>"
```

---

## Formato do .crom-project

Cada projeto contém um arquivo `.crom-project` com metadados:

```
name=meu-site
owner=pedrodev
description=Site pessoal
stack=web
created=2026-05-01T12:00:00Z
status=ativo
```

O admin pode consultar esses arquivos remotamente para saber o que cada membro está fazendo.

---

## FAQ

### Posso usar Docker?
Usamos **Podman**, que é idêntico ao Docker mas 100% seguro (rootless). Você pode usar os comandos `podman run` ou usar o alias `docker run` que funciona da mesma forma. Exemplo: `docker run -d -p 3000:80 nginx`.

### Posso instalar pacotes no servidor?
Não. Apenas o admin (root) pode instalar pacotes via `apt`. Entre em contato com **MRJ** pelo Discord ou por mensagem direta.

### Posso rodar servidores web?
Sim! Rode localmente na sua porta (ex: 8080) e use o comando `crom-ws publish meu-projeto 8080` para o servidor gerar o subdomínio e expor para a internet. Não tente acessar portas abaixo de 1024.

### Meus arquivos são privados?
Sim, outros membros não acessam seu diretório. O admin (root) tem acesso para auditoria, mas não monitora ativamente — veja [Política de Acesso](politica-acesso.md) para detalhes.

### Posso usar git?
Sim! Git está disponível. Clone repositórios dentro de `~/projetos/`.

### Quanto espaço tenho?
O disco é compartilhado. Use com responsabilidade. Verifique com `crom-ws status`.

### Em qual VPS estou?
Você foi alocado em uma VPS ao receber sua conta. Ao conectar via SSH, o endereço que você usa indica a VPS (ex: `vps1.crom.me` = Pilares, `vps2.crom.me` = Forja). Se precisar acesso em outra VPS, fale com **MRJ**.
