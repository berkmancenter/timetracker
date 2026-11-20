#!/bin/bash

# Builds the Vue front-end (front/) into public/index_f.html and
# public/front_assets, where Rails serves it from. Run it after changing the
# front-end, e.g. `./docker/shell_dev.sh bin/compile-front.sh`.
#
# The VITE_* settings come from front/.env. docker/entrypoint.sh makes it on
# every container start, when it's missing it's made here from the VITE_ lines
# of .env.$APP_ENV (or .env).

set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f front/.env ]; then
  for env_file in ".env.${APP_ENV:-development}" .env; do
    if [ -f "$env_file" ]; then
      grep '^VITE_' "$env_file" > front/.env || true
      echo "Created front/.env from the VITE_ settings in $env_file"
      break
    fi
  done
fi

cd front
exec ./deploy.sh
