# Sacristia Digital

Sistema para controle da escala do MESC (Ministros Extraordinários da Sagrada Comunhão) e controle financeiro da sacristia.

## Requisitos

- **Ruby** 3.2 ou superior
- **PostgreSQL** 14+
- **Node.js** (para Tailwind CSS em desenvolvimento)

## Configuração inicial

```bash
# Instalar dependências
bundle install

# Configurar banco de dados
rails db:create db:migrate

# Executar seeds (dados iniciais)
rails db:seed

# Compilar assets Tailwind
rails tailwindcss:build
```

## Desenvolvimento

```bash
# Iniciar servidor (em um terminal)
rails server

# Em outro terminal, watch do Tailwind para desenvolvimento
rails tailwindcss:watch
```

Ou use o Procfile.dev com Foreman/Overmind:

```bash
bin/dev
```

## Docker

```bash
# Subir ambiente completo
docker compose up -d

# Executar migrações e seeds
docker compose exec web rails db:migrate
docker compose exec web rails db:seed
```

## Deploy (produção / DigitalOcean App Platform)

O Rails **não sobe** em `RAILS_ENV=production` sem chave de sessão/cookies. Defina no painel do app (Environment Variables):

| Variável | Obrigatório | Descrição |
|----------|-------------|-----------|
| `SECRET_KEY_BASE` | **Sim** | String longa e secreta. Gere na sua máquina: `bin/rails secret` ou `openssl rand -hex 64`. **Não commite** no repositório. |
| `RAILS_SERVE_STATIC_FILES` | Opcional | Padrão no código é **`true`**: o Puma entrega CSS/JS em `public/assets` (gerados no `docker build` com `assets:precompile`). Use `false` só se um CDN ou nginx na frente servir os estáticos. |
| `RAILS_ENV` | Recomendado | `production` |
| `APP_HOST` | Recomendado | Host público sem esquema, ex.: `sacristia-digital-app-xxxx.ondigitalocean.app` (usado no mailer e em hosts permitidos). |
| `ALLOWED_HOSTS` | Opcional | Domínios extras separados por vírgula, ex.: `meusite.com.br,www.meusite.com.br` |
| `DATABASE_URL` | **Recomendado** | Connection string completa do PostgreSQL gerenciado (DigitalOcean → Database → Connection Details). Se existir, o Rails ignora `DATABASE_HOST` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` separados. |
| `DATABASE_HOST`, `DATABASE_USERNAME`, `DATABASE_PASSWORD` | Se não usar URL | Use o usuário e senha do painel (ex.: `doadmin`). O projeto aceita também `SACRISTIA_DIGITAL_DATABASE_PASSWORD` como fallback da senha. |
| `DATABASE_NAME` | Se não usar URL | Nome do banco (no DO costuma ser `defaultdb` até você criar outro). |
| `DATABASE_SSLMODE` | Opcional | O `bin/docker-entrypoint` exporta `PGSSLMODE` com padrão **`disable`** para evitar **dh key too small** (OpenSSL 3 × TLS antigo). Defina `require` quando o PostgreSQL gerenciado estiver atualizado. A senha continua obrigatória: use **`DATABASE_URL`** completa ou **`DATABASE_PASSWORD`**. |

Variáveis de exemplo para desenvolvimento local: [.env.example](.env.example).

## Usuários de demonstração (após seeds)

| E-mail | Senha | Perfil |
|--------|-------|--------|
| admin@sacristiadigital.local | 123456 | Administrador |
| coordenador@sacristiadigital.local | 123456 | Coordenador |
| ministro@sacristiadigital.local | 123456 | Ministro |

## Stack

- Ruby 3.3 / Rails 8
- PostgreSQL
- Tailwind CSS
- Hotwire (Turbo + Stimulus)
- Devise (autenticação)
- Kaminari (paginação)
- Pundit (autorização)
- Simple Form

## Estrutura do projeto

- **Fase 1** (concluída): Base, autenticação, models, migrations, seeds, Docker
- **Fase 2**: CRUDs de ministros, sacerdotes, tipos de serviço, calendário base
- **Fase 3**: Geração de escala mensal, equipes de plantão, eventos extras
- **Fase 4**: Dashboard, calendário, relatórios, espórtulas
- **Fase 5**: Refino visual e UX

<!-- CHECKPOINT id="ckpt_mmxydv2s_h16jx3" time="2026-03-19T20:59:19.060Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->

<!-- CHECKPOINT id="ckpt_mmxyqq1k_029tok" time="2026-03-19T21:09:19.064Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->

<!-- CHECKPOINT id="ckpt_mmy0vvu5_wizucb" time="2026-03-19T22:09:19.085Z" note="auto" fixes=0 questions=0 highlights=0 sections="" -->
