#!/bin/zsh
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 7: SEED ────────────────────────────┐"
echo "│  Seed the database with some useful data  │"
echo "└───────────────────────────────────────────┘"
echo
docker compose --env-file "${ENV}" run --rm artisan db:seed
docker compose --env-file "${ENV}" run --rm artisan script:run scripts/init_opzet.script
