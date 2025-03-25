#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
COMPOSE_FILE="${COMPOSE_FILE:=docker-compose.yml}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 1: SET UP WORKSPACE ──────────┐"
echo "│  Copy the configs to our workspace  │"
echo "└─────────────────────────────────────┘"
echo
echo "     Domain: ${DOMAIN}"
echo "Certificate: ${CERT}"
echo "        Key: ${KEY}"

echo
echo "    ┌─ SELF-SIGNED.CERT AND KEY ───────────────────────────────────────┐"
echo "    │  Create self signed certificate and key in '.docker/httpd/cert'  │"
echo "    └──────────────────────────────────────────────────────────────────┘"
/opt/homebrew/bin/mkcert -key-file "${PWD}/.docker/httpd/cert/${KEY}" \
  -cert-file "${PWD}/.docker/httpd/cert/${CERT}" "${DOMAIN}"

if [ ! -d "${HOST_INSTALL_PATH}" ]; then
echo
echo "    ┌─ SVN Checkout ──────────────────────────────┐"
echo "    │  Perform SVN Checkout of the zWaste branch  │"
echo "    └─────────────────────────────────────────────┘"
  CURRENT_DIR=${PWD}
  mkdir -p "${HOST_INSTALL_PATH}"
  cd "${HOST_INSTALL_PATH}" || exit
  svn checkout "${SVN_CHECKOUT_URL}" .
  cd "${CURRENT_DIR}" || exit
fi

echo
echo "    ┌─ UPDATE HOSTS FILE ─────────────────────────────────────┐"
echo "    │  Add the domain to the hosts file if not yet available  │"
echo "    └─────────────────────────────────────────────────────────┘"
echo
if (( $(grep -c "${DOMAIN}" "/etc/hosts" | tail -1) )); then
  echo "Domain found in '/etc/hosts' file – no change needed"
else
  echo "Domain not found in '/etc/hosts' file"
	echo "${HOST_PASSWORD}" | sudo -S sh -c "echo '127.0.0.1       ${DOMAIN}' >> /etc/hosts"
	echo "Added '127.0.0.1       ${DOMAIN}' to '/etc/hosts'"
fi

echo
echo "    ┌─ DOCKER-UP ────────────────────────────────────────────┐"
echo "    │  Bringing up the 'httpd' service and it's dependencies │"
echo "    └────────────────────────────────────────────────────────┘"
echo "${COMPOSE_FILE}"
echo
UID=$(id -u) GID=$(id -g) CLIENT_NAME=${CLIENT_NAME} docker compose --file "${COMPOSE_FILE}" --env-file "${ENV}" up -d httpd
