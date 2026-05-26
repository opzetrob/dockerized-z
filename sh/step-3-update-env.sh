#!/bin/zsh
# shellcheck source=.env.example
source "${ENV}"
HOST_INSTALL_PATH="${HOST_INSTALL_PATH:=$HOME/PhpstormProjects/zwaste}"
DB_HOST="${DB_HOST:=mysql}"
DB_DATABASE="${DB_DATABASE:=zcalendar}"
DB_USERNAME="${DB_USERNAME:=zcalendar}"
DB_PASSWORD="${DB_PASSWORD:=zcalendar}"
MAIL_HOST="${MAIL_HOST:=mailhog}"
MAIL_PORT="${MAIL_PORT:=1025}"
APP_DEBUG="${APP_DEBUG:=false}"
APP_LOG_LEVEL="${APP_LOG_LEVEL:=error}"
export PATH=$PATH:/usr/local/bin

echo
echo "┌─ STEP 3: UPDATE-ENV ──────────────────┐"
echo "│  Apply .env variable overrides        │"
echo "└───────────────────────────────────────┘"
echo
sed -i "" \
    -e "s/\(^APP_KEY=.*\)/\1/" \
    -e "s/^APP_DEBUG=.*/APP_DEBUG=${APP_DEBUG}/" \
    -e "s/^APP_LOG_LEVEL=.*/APP_LOG_LEVEL=${APP_LOG_LEVEL}/" \
    -e "s/^APP_URL=.*/APP_URL=${DOMAIN}/" \
    -e "s/^DB_HOST=.*/DB_HOST=${DB_HOST}/" \
    -e "s/^DB_TESTING_HOST=.*/DB_TESTING_HOST=${DB_HOST}/" \
    -e "s/^DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" \
    -e "s/^DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" \
    -e "s/^DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" \
    -e "s/\(^BAG_DB_PASSWORD=.*\)/\1/" \
    -e "s/^MAIL_HOST=.*/MAIL_HOST=mailhog/" \
    -e "s/^MAIL_PORT=.*/MAIL_PORT=1025/" "${HOST_INSTALL_PATH}/.env"

echo "Updated:"
#echo "APP_KEY"
echo "    APP_DEBUG: ${APP_DEBUG}"
echo "APP_LOG_LEVEL: ${APP_LOG_LEVEL}"
echo "      APP_URL: ${DOMAIN}"
echo "      DB_HOST: ${DB_HOST}"
echo "  DB_DATABASE: ${DB_DATABASE}"
echo "  DB_USERNAME: ${DB_USERNAME}"
echo "  DB_PASSWORD: ********"
#echo "BAG_DB_PASSWORD"
echo "    MAIL_HOST: mailhog"
echo "    MAIL_PORT: 1025"

echo
echo "    ┌─ CLEAR LARAVEL CONFIG CACHE ────────────────────────────┐"
echo "    │  Clear cached config so Laravel reads the new .env file │"
echo "    └─────────────────────────────────────────────────────────┘"
COMPOSE_FILE="${COMPOSE_FILE:=docker-compose.yml:docker-compose.81.yml}" docker compose run --rm artisan config:clear
