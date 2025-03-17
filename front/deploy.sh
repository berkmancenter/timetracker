#!/bin/bash

set -o allexport
. /app/front/.env
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
