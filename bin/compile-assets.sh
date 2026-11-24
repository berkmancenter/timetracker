#!/bin/sh

# Precompiles the Rails assets (sign in pages, layouts) into public/assets.
# Not needed in development, where assets are compiled on request and old files
# in public/assets would be served instead (`bin/rails assets:clobber` removes them).

set -eu

cd "$(dirname "$0")/.."

RAILS_ENV="${RAILS_ENV:-production}" SECRET_KEY_BASE_DUMMY="${SECRET_KEY_BASE_DUMMY:-1}" bundle exec rails assets:precompile
