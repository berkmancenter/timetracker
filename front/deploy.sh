#!/bin/bash

# Builds the front-end into ../public, see bin/compile-front.sh.

set -e

CONFIG_FILE=vite.config.js
if [ ! -f "$CONFIG_FILE" ]; then
  echo 'You must run the script from the "front" directory.'
  exit 1
fi

if [ -f .env ]; then
  set -o allexport
  . ./.env
  set +o allexport
fi

if [ -z "$VITE_BASE_PATH" ]; then
  BASE_PATH="/"
else
  BASE_PATH="$VITE_BASE_PATH"
fi

yarn install
yarn run build --base="$BASE_PATH"
rm -rf ../public/index_f.html ../public/front_assets
mv dist/index.html ../public/index_f.html
cp -R dist/front_assets ../public
