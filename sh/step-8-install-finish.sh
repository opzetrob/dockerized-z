#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 8: INSTALL-FINISH ──────────────────────┐"
echo "│  Finished installation of the zWaste project  │"
echo "└───────────────────────────────────────────────┘"
echo
echo "Domain available at: https://${DOMAIN}"
