#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
HOST_INSTALL_PATH="${HOST_INSTALL_PATH:=$HOME/PhpstormProjects/zwaste}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 5: NPM CI ──────────────────────┐"
echo "│  Run 'npm ci'                         │"
echo "└───────────────────────────────────────┘"
echo
# Install packages without running postinstall
NPM_TOKEN="${NPM_TOKEN}" \
docker compose --env-file "${ENV}" run --rm npm ci --ignore-scripts

# Install devDependencies inside zwaste-ui so the build tools are available
NPM_TOKEN="${NPM_TOKEN}" \
docker compose --env-file "${ENV}" run --rm npm install --prefix node_modules/@opzetter/zwaste-ui --include=dev

# Now run the postinstall manually
NPM_TOKEN="${NPM_TOKEN}" \
docker compose --env-file "${ENV}" run --rm npm run --prefix node_modules/@opzetter/zwaste-webpack-config postinstall

echo
echo "    ┌─ Set NPM public dir ──────────────────────────────────────────────┐"
echo "    │  Set the public dir into which the zwaste-ui code will be copied  │"
echo "    └───────────────────────────────────────────────────────────────────┘"
echo
npm_env_dir="node_modules/@opzetter/zwaste-ui"
NPM_TOKEN="${NPM_TOKEN}" \
docker compose --env-file "${ENV}" run --rm npm run --prefix "/var/www/html/${npm_env_dir}" dev "${CLIENT_NAME}"
