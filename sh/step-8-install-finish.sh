#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
HOST_INSTALL_PATH="${HOST_INSTALL_PATH:=$HOME/PhpstormProjects/zwaste}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 8: INSTALL-FINISH ──────────────────────┐"
echo "│  Finished installation of the zWaste project  │"
echo "└───────────────────────────────────────────────┘"
echo
echo "Active project:      ${CLIENT_NAME}"
echo "Domain available at: https://${DOMAIN}"
echo "Install path:        ${HOST_INSTALL_PATH}"
