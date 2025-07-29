#!/bin/zsh
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 4: COMPOSER INSTALL ────────────────────────┐"
echo "│  Run 'composer install -o --prefer-dist'          │"
echo "└───────────────────────────────────────────────────┘"
echo

docker compose --env-file "${ENV}" run -T --rm composer install -o --prefer-dist --ignore-platform-req=ext-http
