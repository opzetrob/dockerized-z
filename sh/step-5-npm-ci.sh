#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 5: NPM CI ──────────────────────┐"
echo "│  Run 'npm ci'                         │"
echo "└───────────────────────────────────────┘"
echo
#eval "$(ssh-agent)"
#NPM_TOKEN="${NPM_TOKEN}" \
#docker compose --env-file "${ENV}" run --rm npm ci
npm ci --prefix "/users/robburgers/PhpstormProjects/zwaste-new-next" dev "${CLIENT_NAME}"

echo
echo "    ┌─ Set NPM public dir ──────────────────────────────────────────────┐"
echo "    │  Set the public dir into which the zwaste-ui code will be copied  │"
echo "    └───────────────────────────────────────────────────────────────────┘"
echo
npm_env_dir="node_modules/@opzetter/zwaste-ui"
#sed -i '' -e "s~^var DESTINATION_PATH_DEV = '';~var DESTINATION_PATH_DEV = '/var/www/html/public';~" "${HOST_INSTALL_PATH}/${npm_env_dir}/webpack_general.js"

#NPM_TOKEN="${NPM_TOKEN}" \
#docker compose --env-file "${ENV}" run --rm npm run --prefix "/var/www/html/${npm_env_dir}" dev "${CLIENT_NAME}"
npm run --prefix "/users/robburgers/PhpstormProjects/zwaste-new-next/${npm_env_dir}" dev "${CLIENT_NAME}"
