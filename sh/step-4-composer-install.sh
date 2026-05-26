#!/bin/zsh
HOST_INSTALL_PATH="${HOST_INSTALL_PATH:=$HOME/PhpstormProjects/zwaste}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 4: COMPOSER INSTALL ────────────────────────┐"
echo "│  Run 'composer install -o --prefer-dist'          │"
echo "└───────────────────────────────────────────────────┘"
echo

docker compose --env-file "${ENV}" run -T --rm composer install -o --prefer-dist --ignore-platform-reqs
