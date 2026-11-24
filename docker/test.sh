#!/bin/bash

# Runs the tests in the test containers (docker/docker-compose.test.yml), like CI.
#
#   ./docker/test.sh                          back-end and front-end tests
#   ./docker/test.sh back                     only the back-end tests (rspec)
#   ./docker/test.sh back spec/models         rspec with these arguments
#   ./docker/test.sh front                    only the front-end tests (vitest)
#   ./docker/test.sh front src/lib            vitest with these arguments
#
# The code is copied into the image, so the image is built again when the code
# changed (Docker reuses what didn't change). The test database is made again
# from the migrations every run.

set -e
cd "$(dirname "$0")/.."

suite="${1:-all}"
case "$suite" in
  all | back | front) shift || true ;;
  *)
    echo "Usage: $0 [all|back|front] [rspec or vitest arguments]" >&2
    exit 1
    ;;
esac

compose=(docker compose -f docker/docker-compose.test.yml)

"${compose[@]}" up -d --build

# The entrypoint builds the front-end and prepares the database before the
# server starts.
echo "Waiting for the app container..."
ready=false
for _ in $(seq 1 300); do
  logs=$("${compose[@]}" logs app)
  if grep -q "Database ready and migrated" <<< "$logs"; then
    ready=true
    break
  fi
  if grep -q "Database setup failed" <<< "$logs"; then
    break
  fi
  sleep 2
done
if [ "$ready" != "true" ]; then
  "${compose[@]}" logs --tail 50 app
  echo "The app container didn't get ready, see the log above." >&2
  exit 1
fi

run() {
  "${compose[@]}" exec -T app bash -c "$1"
}

args=""
if [ $# -gt 0 ]; then
  args=$(printf ' %q' "$@")
fi

if [ "$suite" = "all" ] || [ "$suite" = "back" ]; then
  run "RAILS_ENV=test bin/rails db:drop db:create db:migrate && bundle exec rspec$args"
fi

if [ "$suite" = "all" ] || [ "$suite" = "front" ]; then
  run "cd front && yarn test$args"
fi
