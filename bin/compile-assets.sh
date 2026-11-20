#!/bin/sh

# Precompiles the Rails assets (sign in pages, layouts) into public/assets,
# docker/entrypoint.sh runs it in production. Not needed in development, there
# the assets are compiled on request and old files in public/assets would be
# served instead (`bin/rails assets:clobber` removes them).
#
# The asset gems (dartsass-sprockets, terser) are only in the development,
# test and assets groups, so the assets are compiled in the development
# environment.

set -eu

cd "$(dirname "$0")/.."

RAILS_ENV=development SECRET_KEY_BASE_DUMMY="${SECRET_KEY_BASE_DUMMY:-1}" bundle exec rails assets:precompile
