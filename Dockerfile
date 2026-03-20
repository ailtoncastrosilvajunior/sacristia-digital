# Sacristia Digital - Dockerfile
# Ruby 3.3 + Rails 8 + PostgreSQL

FROM ruby:3.3.6-slim-bookworm AS base

# Instalar dependências do sistema
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libpq-dev \
    postgresql-client \
    node-gyp \
    pkg-config \
    python3 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependências Ruby (path fixo para não ser sobrescrito pelo volume)
COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle config set --local without 'development test' && \
    bundle install -j4

# Copiar código da aplicação
COPY . .

# Pré-compilar assets (inclui Tailwind)
RUN bundle exec rails tailwindcss:build 2>/dev/null || true
RUN bundle exec rails assets:precompile

# Expor porta
EXPOSE 3000

# Comando padrão
CMD ["./bin/docker-entrypoint"]
