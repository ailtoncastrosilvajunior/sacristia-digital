# Sacristia Digital - Dockerfile
# Ruby 3.3 + Rails 8 + PostgreSQL

FROM ruby:3.3.6-slim-bookworm AS base

# Instalar dependências do sistema (+ Chromium/Node para Grover → cartaz PNG)
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    postgresql-client \
    node-gyp \
    pkg-config \
    python3 \
    git \
    curl \
    ca-certificates \
    nodejs \
    npm \
    chromium \
    fonts-liberation \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium

WORKDIR /app

ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT="development:test"

# Instalar dependências Ruby (path fixo para não ser sobrescrito pelo volume)
COPY Gemfile Gemfile.lock* ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local path '/usr/local/bundle' && \
    bundle config set --local without 'development test' && \
    bundle install -j4

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

# Copiar código da aplicação
COPY . .

# Pré-compilar assets (inclui Tailwind) — exige RAILS_ENV=production e chave dummy no build
RUN SECRET_KEY_BASE=dummy-build-key bundle exec rails tailwindcss:build 2>/dev/null || true
RUN SECRET_KEY_BASE=dummy-build-key bundle exec rails assets:precompile

# Expor porta
EXPOSE 3000

# Comando padrão
CMD ["./bin/docker-entrypoint"]
