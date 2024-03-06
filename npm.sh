#!/bin/bash
source .env

# Will run npm in $ZWASTE_INSTALL_PATH
# When de environment is "development" and the correct Node version is available, it will be run on the host machine,
# otherwise the NPM Docker container will be used
npm_arg=$1
node_major=$(node -v | cut -d. -f1)
node_major_required="v18"

if [[ "$ENVIRONMENT" == "development" && "$node_major" == "$node_major_required" ]]
then
  cd "$ZWASTE_INSTALL_PATH" && npm "$npm_arg" --prefix "$ZWASTE_INSTALL_PATH"
else
  NPM_TOKEN="$NPM_TOKEN" \
	SSH_AUTH_SOCK="$SSH_AUTH_SOCK" \
	ZWASTE_INSTALL_PATH="$ZWASTE_INSTALL_PATH" \
	docker compose run npm "$npm_arg"
fi
