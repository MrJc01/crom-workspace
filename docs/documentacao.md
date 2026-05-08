# 📘 Documentação — CROM Workspace (crom-ws)

> Ferramenta de linha de comando para membros CROM gerenciarem seus projetos no servidor.
> Versão: 1.1.0

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
- Containers Podman com **auto-restart** nativo via Quadlets
- Publicação web com **HTTPS automático** (Let's Encrypt)
- Cada ação é **registrada automaticamente** para auditoria
- Interface colorida e intuitiva no terminal

---

## Instalação

O `crom-ws` já vem **pré-instalado** no servidor. Qualquer membro pode usá-lo assim que fizer login via SSH.

Se precisar reinstalar (como root):
```bash
cd /tmp && bash install.sh
```

---

## Comandos — Projetos

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
3. Registra o projeto no log central
4. Loga a ação: `CREATE_PROJECT`

**Exemplo interativo:**
```
$ crom-ws init
  Nome do projeto: api-crom
  Descrição: API REST para o ecossistema
  Stack (go/python/web): go
  ✓ Projeto 'api-crom' criado em /home/membro/projetos/api-crom
```

**Aliases:** `crom-ws new`

---

### `crom-ws list` — Listar projetos

Mostra todos os projetos do membro com nome, stack, descrição e data.

```bash
crom-ws list
```

**Aliases:** `crom-ws ls`

---

### `crom-ws info [projeto]` — Ver detalhes

Sem argumento, mostra informações do workspace. Com argumento, mostra detalhes do projeto específico.

```bash
crom-ws info              # Status geral do workspace
crom-ws info api-crom     # Detalhes do projeto
```

**Aliases:** `crom-ws show`

---

### `crom-ws delete [projeto]` — Deletar projeto

Remove um projeto permanentemente. Pede confirmação digitando o nome.

```bash
crom-ws delete api-crom
```

> ⚠️ **Atenção:** Isso deleta todos os arquivos do projeto. Não tem desfazer.

**Aliases:** `crom-ws rm`

---

## Comandos — Publicação Web

### `crom-ws publish [projeto] [porta]` — Publicar na web

Expõe o seu projeto local (rodando numa porta) para a internet através de um subdomínio oficial com **HTTPS automático**.

```bash
crom-ws publish api-crom 8080
```
```
  ℹ  Solicitando publicação para api-crom na porta 8080...
  ✓  Projeto publicado com sucesso!
  ✓  URL: http://api-crom-membro.vps1.crom.me (HTTPS ativado)
```

> ℹ️ **O subdomínio gerado depende da VPS onde você está:**
> - Na VPS Guardiões: `api-crom-membro.crom.me`
> - Na VPS Pilares: `api-crom-membro.vps1.crom.me`
> - Na VPS Forja: `api-crom-membro.vps2.crom.me`

> ⚠️ **Nota:** Você precisa estar rodando o seu app na porta informada para o site abrir.

---

### `crom-ws unpublish [projeto]` — Remover da web

Derruba o acesso público ao seu projeto imediatamente.

```bash
crom-ws unpublish api-crom
```

---

### `crom-ws ports` — Ver rede do ecossistema

Lista todas as portas em uso no servidor e os respectivos subdomínios.

```bash
crom-ws ports
```

---

## Comandos — Containers (Podman)

O `crom-ws` integra com o **Podman** através de Quadlets do Systemd. Containers criados por aqui **reiniciam automaticamente** quando a VPS reboota — sem precisar de Docker, daemon, ou root.

### `crom-ws podman run <nome> <imagem> <porta>` — Criar container

Cria e inicia um container com auto-restart permanente.

```bash
crom-ws podman run meu-redis redis:alpine 6379
```
```
  ℹ  Gerando Quadlet para 'meu-redis'...
  ℹ  Recarregando systemd do usuário...
  ℹ  Habilitando e iniciando o serviço...
  ✓  Container 'meu-redis' está rodando!
  ✓  Imagem: redis:alpine
  ✓  Porta: 6379
  ✓  Volume: ~/.local/share/crom-volumes/meu-redis
  ✓  Auto-restart: ATIVO (sobrevive reboot)

  Dica: Para publicar na web, rode:
  crom-ws publish meu-redis 6379
```

**Outros exemplos:**
```bash
# Subir o n8n (automação)
crom-ws podman run n8n n8nio/n8n 5678

# Subir um banco PostgreSQL
crom-ws podman run postgres postgres:16-alpine 5432

# Subir um Nginx
crom-ws podman run web nginx:alpine 8080
```

---

### `crom-ws podman stop <nome>` — Parar container

```bash
crom-ws podman stop meu-redis
```

---

### `crom-ws podman start <nome>` — Iniciar container

```bash
crom-ws podman start meu-redis
```

---

### `crom-ws podman rm <nome>` — Remover container

Remove o Quadlet e desabilita o serviço. **Os dados do volume são preservados.**

```bash
crom-ws podman rm meu-redis
```

---

### `crom-ws podman list` — Listar containers

```bash
crom-ws podman list
```
```
  🐳 CONTAINERS GERENCIADOS (Quadlets)

  SERVIÇO         IMAGEM                    PORTA    STATUS
  meu-redis        redis:alpine              6379    ● ATIVO
  n8n              n8nio/n8n                 5678    ○ PARADO
```

---

### `crom-ws podman logs <nome>` — Ver logs

Exibe as últimas 50 linhas de log do container.

```bash
crom-ws podman logs meu-redis
```

---

## Comandos — Sistema

### `crom-ws status` — Status do workspace

```bash
crom-ws status
```

**Aliases:** `crom-ws st`

### `crom-ws history [n]` — Histórico de ações

```bash
crom-ws history      # últimas 20
crom-ws history 5    # últimas 5
```

**Aliases:** `crom-ws log`

### `crom-ws help` — Ajuda

```bash
crom-ws help
```

### `crom-ws version` — Versão

```bash
crom-ws version
# crom-ws v1.1.0
```

---

## Estrutura de arquivos

### No home do membro
```
~/
├── projetos/                        # Todos os projetos
│   ├── meu-site/
│   │   ├── src/
│   │   ├── docs/
│   │   ├── scripts/
│   │   ├── README.md
│   │   └── .crom-project
│   └── api-crom/
│       └── ...
│
├── .crom/                           # Configuração do workspace
│   ├── config
│   └── history.log
│
├── .config/containers/systemd/      # Quadlets do Podman
│   ├── meu-redis.container
│   └── n8n.container
│
└── .local/share/crom-volumes/       # Volumes persistentes dos containers
    ├── meu-redis/
    └── n8n/
```

### No servidor (somente admin vê)
```
/usr/local/bin/crom-ws                       # CLI principal
/usr/local/lib/crom-ws/modules/              # Módulos da CLI
    ├── projects.sh
    ├── publish.sh
    └── podman.sh
/usr/local/sbin/crom-publish-helper          # Helper de Nginx (root)
/var/log/crom-membros/                       # Logs centrais
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
| `DELETE_PROJECT` | `crom-ws delete` |
| `PUBLISH_PROJECT` | `crom-ws publish` |
| `UNPUBLISH_PROJECT` | `crom-ws unpublish` |
| `VIEW_PORTS` | `crom-ws ports` |
| `PODMAN_RUN` | `crom-ws podman run` |
| `PODMAN_STOP` | `crom-ws podman stop` |
| `PODMAN_START` | `crom-ws podman start` |
| `PODMAN_RM` | `crom-ws podman rm` |
| `PODMAN_LIST` | `crom-ws podman list` |

---

## FAQ

### Posso usar Docker?
Usamos **Podman**, que é idêntico ao Docker mas 100% seguro (rootless). Use `crom-ws podman run` para criar containers com auto-restart, ou rode `podman run` diretamente para uso manual.

### Meu container morre quando a VPS reinicia?
**Não**, se você criou com `crom-ws podman run`. O sistema gera um Quadlet do Systemd que garante que o container reinicie automaticamente no boot. Se você criou manualmente com `podman run`, ele **não** sobrevive a reboots.

### Posso instalar pacotes no servidor?
Não. Apenas o admin (root) pode instalar pacotes via `apt`. Entre em contato com **MRJ** pelo Discord.

### Posso rodar servidores web?
Sim! Rode localmente na sua porta e use `crom-ws publish meu-projeto 8080` para expor na web com HTTPS automático.

### Meus arquivos são privados?
Sim, outros membros não acessam seu diretório. Veja [Política de Acesso](politica-acesso.md).

### Posso usar git?
Sim! Git está disponível. Clone repositórios dentro de `~/projetos/`.

### Quanto espaço tenho?
O disco é compartilhado. Use com responsabilidade. Verifique com `crom-ws status`.

### Como vejo o tamanho do meu disco?
```bash
du -sh ~ 2>/dev/null        # Tamanho total (oculta erros do Podman)
du -sh ~/projetos/*          # Tamanho por projeto
```
