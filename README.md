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
