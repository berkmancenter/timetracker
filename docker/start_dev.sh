#!/bin/bash

# Starts the development environment (app + db).
# --demo loads the demo data (see "Demo data" in README.md).
# Other arguments are passed to `docker compose up`, e.g. `-d` or `--build`.

set -e
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  cp .env.sample .env
  echo "Created .env from .env.sample"
fi

args=()
for arg in "$@"; do
  if [ "$arg" = "--demo" ]; then
    export SEED_DEMO_DATA=true
  else
    args+=("$arg")
  fi
done

echo "App: http://127.0.0.1:6868, Mailcatcher: http://127.0.0.1:6878"
if [ "$SEED_DEMO_DATA" = "true" ]; then
  echo "Demo data: loaded on start, log in as maya@demo.timetracker.test / timetracker-demo-password"
  echo "           (accounts and things to try: ./docker/seed_dev.sh info)"
fi

exec docker compose -f docker/docker-compose.dev.yml --env-file .env up "${args[@]}"
