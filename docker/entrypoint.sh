#!/bin/bash
set -e

APP_ENV="${APP_ENV:-${RAILS_ENV:-development}}"

# Define env files
MAIN_ENV_FILE=".env.${APP_ENV}"
FRONT_ENV_FILE="/app/front/.env"
BASHRC_FILE="/home/timetracker/.bashrc"

# This key was committed in .env.sample, so it is public and must never be used.
PUBLIC_SAMPLE_SECRET="d8b1bd64eca5e6bddd8f4c1f1fc4b0e869890868f7de5954c1aa4a0321ac00300a506a1bbb44bd2702a63dc006e8d96c1a20a86663bf0a76ba2f2e344ce31532"

if [ "$APP_ENV" != "production" ]; then
  # Create the main environment file if it doesn't exist
  if [ ! -f "$MAIN_ENV_FILE" ]; then
    cp .env.sample "$MAIN_ENV_FILE"
    sed -i "s/development/${APP_ENV}/g" "$MAIN_ENV_FILE"
    echo "✅ Created $MAIN_ENV_FILE"
  fi

  # New env files get their own secret key, so do older ones copied with the
  # public sample key (this signs out everybody once) or without a key.
  CURRENT_SECRET=$(grep "^SECRET_KEY_BASE=" "$MAIN_ENV_FILE" | tail -n 1 | cut -d= -f2- || true)
  if [ -z "$CURRENT_SECRET" ] || [ "$CURRENT_SECRET" = "$PUBLIC_SAMPLE_SECRET" ]; then
    NEW_SECRET=$(ruby -rsecurerandom -e 'puts SecureRandom.hex(64)')
    if grep -q "^SECRET_KEY_BASE=" "$MAIN_ENV_FILE"; then
      sed -i "s/^SECRET_KEY_BASE=.*/SECRET_KEY_BASE=${NEW_SECRET}/" "$MAIN_ENV_FILE"
    else
      echo "SECRET_KEY_BASE=${NEW_SECRET}" >> "$MAIN_ENV_FILE"
    fi
    echo "🔑 Set a new SECRET_KEY_BASE in $MAIN_ENV_FILE"
  fi

  # If in test environment, change the port to 9887
  if [ "$APP_ENV" = "test" ]; then
    sed -i 's/6868/9887/' "$MAIN_ENV_FILE"
    echo "🔧 Changed site port to 9887 for test environment"
  fi
fi

echo "🔍 Loading environment: $APP_ENV"

if [ -f "$MAIN_ENV_FILE" ]; then
  INCLUDE_LINE=". $MAIN_ENV_FILE"
  if [ -f "$BASHRC_FILE" ] && ! grep -Fxq "$INCLUDE_LINE" "$BASHRC_FILE"; then
    echo "$INCLUDE_LINE" >> "$BASHRC_FILE"
    echo "✅ Added $MAIN_ENV_FILE to $BASHRC_FILE"
  fi

  set -o allexport
  . "$MAIN_ENV_FILE"
  set +o allexport
fi

if [ "$APP_ENV" = "production" ] && [ "$SECRET_KEY_BASE" = "$PUBLIC_SAMPLE_SECRET" ]; then
  echo "Refusing to start with the public sample SECRET_KEY_BASE in production." >&2
  exit 1
fi

echo "🚀 Starting Rails app in $APP_ENV environment"

# Production email must use an explicitly configured SMTP server. Mailcatcher is
# only a local-development fallback because its web UI has no authentication.
if [ -z "$SMTP_ADDRESS" ]; then
  if [ "$APP_ENV" = "production" ]; then
    echo "SMTP_ADDRESS must be configured in production." >&2
    exit 1
  fi

  echo "SMTP_ADDRESS not set. Using Mailcatcher..."
  export SMTP_ADDRESS="localhost"
  export SMTP_PORT="1025"

  mailcatcher --ip=0.0.0.0 --smtp-port=1025 --http-port=1080 &
  echo "Mailcatcher started on port 1025 (SMTP) and 1080 (Web UI)"
fi

# Remove server pid if it exists.
rm -f tmp/pids/server.pid

# In production, Rails assets and the front-end are precompiled at image build time.
# In development and test, build the front-end from the current env file.
if [ "$APP_ENV" != "production" ]; then
  echo "📝 Copying VITE_ variables to front-end .env file"
  rm -f "$FRONT_ENV_FILE" && touch "$FRONT_ENV_FILE"
  grep "^VITE_" "$MAIN_ENV_FILE" > "$FRONT_ENV_FILE" || true
  echo "✅ VITE_ variables copied to $FRONT_ENV_FILE"

  ./bin/compile-front.sh
fi

echo "📦 [Rails] Preparing database for environment: $APP_ENV"
if bundle exec rails db:prepare RAILS_ENV="$APP_ENV"; then
  echo "✅ [Rails] Database ready and migrated."
else
  echo "❌ [Rails] Database setup failed. Check the logs above for error detail."
  exit 1
fi

# Execute the main process.
exec "$@"
