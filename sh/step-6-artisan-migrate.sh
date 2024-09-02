#!/bin/zsh
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 6: MIGRATE ─────────────────────┐"
echo "│  Migrate the database                 │"
echo "└───────────────────────────────────────┘"
echo
docker compose --env-file "${ENV}" run -T --rm artisan migrate
