# Multi-stage Dockerfile with two targets:
#   - dev:        development and test (Node, Yarn, Chromium, Mailcatcher, all gems)
#   - production: default slim runtime image (precompiled Rails + Vue assets, prod gems only, no Node/Chromium/sudo)

ARG RUBY_VERSION=3.4.13
ARG NODE_VERSION=22

# ---------------------------------------------------------------------------
# 1. Minimal Ruby runtime base
# ---------------------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim AS base

ARG USERNAME=timetracker
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libpq5 \
    libyaml-0-2 \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /app /home/$USERNAME/hist \
    && chown -R $USERNAME:$USERNAME /app /home/$USERNAME/hist

WORKDIR /app

# ---------------------------------------------------------------------------
# 2. Front-end builder (Node + Yarn)
# ---------------------------------------------------------------------------
FROM node:${NODE_VERSION}-slim AS frontend-builder

WORKDIR /app/front

COPY front/package.json front/yarn.lock ./
RUN yarn install --frozen-lockfile

COPY front/ ./

# Build settings of the front-end. How people sign in isn't one of them, the
# server adds it to the page (FrontController), so the image works for all.
ARG VITE_API_URL=""
ARG VITE_BASE_PATH="/"
ARG VITE_ENVIRONMENT="production"

ENV VITE_API_URL=${VITE_API_URL} \
    VITE_BASE_PATH=${VITE_BASE_PATH} \
    VITE_ENVIRONMENT=${VITE_ENVIRONMENT}

RUN mkdir -p /app/public \
    && yarn run build --base="${VITE_BASE_PATH:-/}" \
    && mv dist/index.html /app/public/index_f.html \
    && cp -R dist/front_assets /app/public/front_assets

# ---------------------------------------------------------------------------
# 3. Production Ruby builder (prod gems, Rails assets, bootsnap)
# ---------------------------------------------------------------------------
FROM base AS ruby-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libffi-dev \
    liblzma-dev \
    libpq-dev \
    libssl-dev \
    libyaml-dev \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Node is only needed during asset precompilation (ExecJS/Terser)
COPY --from=frontend-builder /usr/local/bin/node /usr/local/bin/node

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT="development:test"

# The Bundler version from Gemfile.lock, the Ruby image comes with an older one
COPY Gemfile Gemfile.lock ./
RUN gem install bundler --no-document -v "$(awk '/^BUNDLED WITH/ { getline; print $1 }' Gemfile.lock)" \
    && bundle install \
    && rm -rf /usr/local/bundle/cache/*.gem /usr/local/bundle/ruby/*/cache/*.gem

COPY . .
COPY --from=frontend-builder /app/front/node_modules/bulma /app/front/node_modules/bulma

# Leave in /app only what the production image needs, it copies all of it
RUN mkdir -p /app/log /app/tmp/pids \
    && SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile \
    && bundle exec bootsnap precompile --gemfile app/ lib/ \
    && rm -rf front spec tmp/cache/assets

# ---------------------------------------------------------------------------
# 4. Development & test image
# ---------------------------------------------------------------------------
FROM base AS dev

ARG USERNAME=timetracker

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    chromium \
    chromium-driver \
    curl \
    git \
    libffi-dev \
    liblzma-dev \
    libpq-dev \
    libsqlite3-dev \
    libssl-dev \
    libyaml-dev \
    pkg-config \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Bring Node and Yarn from frontend-builder without touching Ruby in /usr/local
COPY --from=frontend-builder /usr/local/bin/node /usr/local/bin/node
COPY --from=frontend-builder /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
    && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx \
    && npm install --global yarn

COPY Gemfile Gemfile.lock ./
RUN gem install bundler --no-document -v "$(awk '/^BUNDLED WITH/ { getline; print $1 }' Gemfile.lock)" \
    && bundle install \
    && gem install mailcatcher

COPY --chown=${USERNAME}:${USERNAME} . .
COPY --from=frontend-builder --chown=${USERNAME}:${USERNAME} /app/front/node_modules /app/front/node_modules

RUN mkdir -p /app/tmp/pids /app/log \
    && bundle exec bootsnap precompile --gemfile app/ lib/ \
    && chown -R ${USERNAME}:${USERNAME} /app/tmp /app/log /usr/local/bundle

COPY docker/entrypoint.sh /usr/bin/timetracker-entrypoint
RUN chmod +x /usr/bin/timetracker-entrypoint

USER ${USERNAME}

ENTRYPOINT ["timetracker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]

# ---------------------------------------------------------------------------
# 5. Production runtime image (default)
# ---------------------------------------------------------------------------
FROM base AS production

ARG USERNAME=timetracker

ENV RAILS_ENV=production \
    APP_ENV=production \
    BUNDLE_WITHOUT="development:test"

COPY --from=ruby-builder /usr/local/bundle /usr/local/bundle
COPY --from=ruby-builder --chown=${USERNAME}:${USERNAME} /app /app
COPY --from=frontend-builder --chown=${USERNAME}:${USERNAME} /app/public/index_f.html /app/public/index_f.html
COPY --from=frontend-builder --chown=${USERNAME}:${USERNAME} /app/public/front_assets /app/public/front_assets

COPY docker/entrypoint.sh /usr/bin/timetracker-entrypoint
RUN chmod +x /usr/bin/timetracker-entrypoint

USER ${USERNAME}

EXPOSE 3000
ENTRYPOINT ["timetracker-entrypoint"]
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
