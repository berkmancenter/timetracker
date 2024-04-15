#!/bin/bash

: ${VITE_ENV:=development}
env_filename=".env"

if [ -f ".env.$VITE_ENV" ]; then
  env_filename=".env.$VITE_ENV"
fi

if [ -f ".env.$VITE_ENV.local" ]; then
  env_filename=".env.$VITE_ENV.local"
fi

set -o allexport
source $env_filename
set +o allexport

CONFIG_FILE=vite.config.js
if [ ! -f "$CONFIG_FILE" ]; then
  echo 'You must run the script from the "front" directory.'
  exit
fi

if [ -z "$VITE_BASE_PATH" ]; then
  BASE_PATH="/"
else
  BASE_PATH="$VITE_BASE_PATH"
fi

yarn install
yarn run build --base=$BASE_PATH
rm -rf ../public/index_f.html ../public/front_assets
mv dist/index.html ../public/index_f.html
cp -R dist/front_assets ../public
