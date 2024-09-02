#!/bin/zsh
exit 0
# shellcheck source=.env.example
source "${ENV}"
export PATH=$PATH:/usr/local/bin
# shellcheck disable=SC2153
echo
echo "┌─ STEP 9: CLEAN UP INSTALLATION FILES ───────────────┐"
echo "│  Remove everything not needed for running the site  │"
echo "└─────────────────────────────────────────────────────┘"
echo
cd "${HOST_INSTALL_PATH}/config/pem/" || exit
find . ! -name "zcalendar-${CLIENT_NAME}.pem" -type f -exec rm -f {} +
cd "${PWD}" || exit
rm -r "${HOST_INSTALL_PATH}/config/env" || true
rm -r "${HOST_INSTALL_PATH}/doc" || true
rm -r "${HOST_INSTALL_PATH}/database/migrations" || true
rm -r "${HOST_INSTALL_PATH}/database/seeders" || true
rm -r "${HOST_INSTALL_PATH}/tests" || true
rm "${HOST_INSTALL_PATH}/.editorconfig" || true
rm "${HOST_INSTALL_PATH}/.gitattributes" || true
rm "${HOST_INSTALL_PATH}/.gitignore" || true
rm "${HOST_INSTALL_PATH}/.styleci.yml" || true
rm "${HOST_INSTALL_PATH}/composer.json" || true
rm "${HOST_INSTALL_PATH}/composer.lock" || true
rm "${HOST_INSTALL_PATH}/copy.js" || true
rm "${HOST_INSTALL_PATH}/install-zwaste-build.js" || true
rm "${HOST_INSTALL_PATH}/install-zwaste-prod.js" || true
rm "${HOST_INSTALL_PATH}/laravel10.md" || true
rm "${HOST_INSTALL_PATH}/package.json" || true
rm "${HOST_INSTALL_PATH}/package-lock.json" || true
rm "${HOST_INSTALL_PATH}/phpcs.xml" || true
rm "${HOST_INSTALL_PATH}/phpstan.neon" || true
rm "${HOST_INSTALL_PATH}/phpunit.xml" || true
rm "${HOST_INSTALL_PATH}/readme.md" || true
rm "${HOST_INSTALL_PATH}/server.php" || true
rm "${HOST_INSTALL_PATH}/workspace.code-workspace" || true

echo "Removed these files and directories:"
echo "All .pem files except 'zcalendar-${CLIENT_NAME}.pem'"
echo "config/env"
echo "doc"
echo "database/migrations"
echo "database/seeders"
echo "tests"
echo "editorconfig"
echo "gitattributes"
echo "gitignore"
echo "styleci.yml"
echo "composer.json"
echo "composer.lock"
echo "copy.js"
echo "install-zwaste-build.js"
echo "install-zwaste-prod.js"
echo "laravel10.md"
echo "package.json"
echo "package-lock.json"
echo "phpcs.xml"
echo "phpstan.neon"
echo "phpunit.xml"
echo "readme.md"
echo "server.php"
echo "workspace.code-workspace"
