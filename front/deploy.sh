#!/bin/bash

FILE=vite.config.js
if [ ! -f "$FILE" ]; then
  echo 'You must run the script from the "front" directory.'
  exit
fi

yarn install
yarn run build
rm -rf ../public/index_f.html ../public/front_assets
mv dist/index.html ../public/index_f.html
cp -R dist/front_assets ../public
