#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
export PATH=$PATH:/usr/local/bin
# shellcheck disable=SC2153
echo
echo "┌─ STEP 2: COPYENVFOR ────────────────────────┐"
echo "│  Copy .env file for CLIENT_NAME/ENVIRONMENT │"
echo "└─────────────────────────────────────────────┘"
echo
function fail {
    printf "Error: Unable to copy .env file for CLIENT_NAME '%s', environment '%s'\n" "${CLIENT_NAME}" "${ENVIRONMENT}" >&2 ## Send message to stderr.
    exit 1
}
cp -f "${HOST_INSTALL_PATH}/config/env/${CLIENT_NAME}/.env-${ENVIRONMENT}" "${HOST_INSTALL_PATH}/.env" || fail
printf "Copied .env file for CLIENT_NAME '%s', environment '%s' to [ROOT]/.env\n" "${CLIENT_NAME}" "${ENVIRONMENT}"
