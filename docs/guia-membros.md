# 📖 Guia do Membro CROM

## Bem-vindo ao Ecossistema CROM

Você recebeu acesso a uma das VPS da comunidade CROM. Este documento explica como acessar, usar e tirar o máximo proveito dos seus recursos.

---

## 🖥️ Infraestrutura Multi-VPS

O ecossistema CROM opera com múltiplas VPS independentes:

| VPS | Domínio SSH | Descrição |
|-----|-------------|-----------|
| Guardiões | `crom.me` | VPS principal — serviços core e CromIA |
| Pilares | `vps1.crom.me` | VPS de membros classificados como Pilar |
| Forja | `vps2.crom.me` | VPS de membros classificados como Forja |

> Ao receber sua conta, o administrador **MRJ** informará em qual VPS você foi alocado e suas credenciais de acesso.

---

## 👤 Como obter uma conta

O acesso às VPS do CROM **não é público**. Para solicitar uma conta:

1. Entre em contato com **MRJ** pelo Discord do Coletivo CROM
2. Aguarde a avaliação e classificação (Pilar ou Forja)
3. Receba suas credenciais (usuário + senha + endereço da VPS)
4. Conecte via SSH e altere sua senha no primeiro acesso

---

## 🔐 Acesso SSH

### Conectar ao servidor

Use o domínio da VPS onde sua conta foi criada:

```bash
# Se você está na VPS Pilares:
ssh SEU_USUARIO@vps1.crom.me

# Se você está na VPS Forja:
ssh SEU_USUARIO@vps2.crom.me

# Se você está na VPS Guardiões:
ssh SEU_USUARIO@crom.me
```

Ao conectar pela primeira vez, o sistema pedirá que você confirme a fingerprint do servidor. Digite `yes`.

### Alterar sua senha (obrigatório no primeiro acesso)
```bash
passwd
```

### Chave SSH (recomendado)
Para conectar sem digitar senha toda vez:
```bash
# Na sua máquina local
ssh-keygen -t ed25519 -C "seu@email.com"
ssh-copy-id SEU_USUARIO@vps1.crom.me
```

---

## 📁 Sua área pessoal

Seu diretório home é: `/home/SEU_USUARIO/`

Você tem permissão total dentro da sua pasta. Use como desejar:
- Projetos pessoais
- Scripts e automações
- Arquivos de configuração

Outros membros **não têm acesso** ao seu diretório. O isolamento é garantido por permissões Linux.

---

## 🚀 Ferramenta `crom-ws`

Todo membro tem acesso ao `crom-ws` — a CLI oficial para gerenciar projetos:

```bash
crom-ws init meu-projeto        # Criar projeto
crom-ws list                    # Listar projetos
crom-ws info meu-projeto        # Ver detalhes
crom-ws publish meu-projeto 8080  # Publicar na web
crom-ws unpublish meu-projeto   # Remover da web
crom-ws ports                   # Ver portas em uso
crom-ws status                  # Status do workspace
crom-ws help                    # Todos os comandos
```

> 📘 Para documentação completa do `crom-ws`, leia: [documentacao.md](documentacao.md)

---

## 🐳 Docker / Podman

Usamos **Podman** (Docker rootless — não precisa de root):

```bash
podman run -d -p 3000:80 nginx
# ou o alias:
docker run -d -p 3000:80 nginx
```

---

## ⚠️ Regras de Uso

1. **Comunique o uso de portas** — Antes de subir algo em uma porta, avise os outros membros da VPS para evitar conflitos
2. **Não acesse diretórios de outros membros**
3. **Não use o servidor para atividades ilegais**
4. **Precisa de algo instalado?** — Fale com **MRJ** para instalar via `apt` (você não tem root)
5. **Mantenha sua senha segura** — Não compartilhe
6. **Use os recursos com responsabilidade** — CPU, RAM e disco são compartilhados

---

## 🌐 Ecossistema CROM

| Recurso | URL |
|---------|-----|
| Portal Principal | [crom.me](https://crom.me) |
| CromIA API | [cromia-api.crom.me](https://cromia-api.crom.me) |
| VPS Pilares | [vps1.crom.me](https://vps1.crom.me) |
| VPS Forja | [vps2.crom.me](https://vps2.crom.me) |
| GitHub | [github.com/MrJc01](https://github.com/MrJc01) |
| Discord | [discord.gg/4b5wqdxreZ](https://discord.gg/4b5wqdxreZ) |

---

## 🆘 Suporte

Problemas com acesso, permissões ou qualquer dúvida? Entre em contato com **MRJ** pelo Discord do Coletivo CROM.
