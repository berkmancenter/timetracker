#!/bin/bash

# Define env files
MAIN_ENV_FILE=".env.${APP_ENV}"
FRONT_ENV_FILE="/app/front/.env"
BASHRC_FILE="/home/timetracker/.bashrc"

# Create the main environment file if it doesn't exist
if [ ! -f "$MAIN_ENV_FILE" ]; then
  cp .env.sample "$MAIN_ENV_FILE"
  sed -i "s/development/${APP_ENV}/g" "$MAIN_ENV_FILE"
fi

# If in test environment, change the port to 9887
if [ "$APP_ENV" = "test" ]; then
  sed -i 's/6868/9887/' "$MAIN_ENV_FILE"
  echo "🔧 Changed site port to 9887 for test environment"
fi

echo "🔍 Loading environment: $APP_ENV"

# Include both environment files in .bashrc if not already included
# and export the environment variables
for ENV_FILE in "$MAIN_ENV_FILE"; do
  INCLUDE_LINE=". $ENV_FILE"
  if ! grep -Fxq "$INCLUDE_LINE" "$BASHRC_FILE"; then
    echo "$INCLUDE_LINE" >> "$BASHRC_FILE"
    echo "✅ Added $ENV_FILE to $BASHRC_FILE"
  else
    echo "✅ $ENV_FILE is already included in $BASHRC_FILE"
  fi

  set -o allexport
  . "$ENV_FILE"
  set +o allexport
done

# Extract VITE_ variables and write them to front/.env
echo "📝 Copying VITE_ variables to front-end .env file"
rm -f "$FRONT_ENV_FILE" && touch "$FRONT_ENV_FILE"
grep "^VITE_" "$MAIN_ENV_FILE" > "$FRONT_ENV_FILE"
echo "✅ VITE_ variables copied to $FRONT_ENV_FILE"

echo "🚀 Starting Rails app in $APP_ENV environment"

# Production email must use an explicitly configured SMTP server. Mailcatcher is
# only a local-development fallback because its web UI has no authentication.
if [ -z "$SMTP_ADDRESS" ]; then
  if [ "$APP_ENV" = "production" ]; then
    echo "SMTP_ADDRESS must be configured in production."
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

# Precompiling assets and building front-end application.
if [ "$APP_ENV" = "production" ]; then
  SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=development rails assets:precompile
fi

# Build the front-end application.
cd front
./deploy.sh
cd /app

echo "📦 [Rails] Preparing database for environment: $APP_ENV"
if bundle exec rails db:prepare RAILS_ENV=$APP_ENV; then
  echo "✅ [Rails] Database ready and migrated."
else
  echo "❌ [Rails] Database setup failed. Check the logs above for error detail."
  exit 1
fi

# Execute the main process.
exec "$@"
