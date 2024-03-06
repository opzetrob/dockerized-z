#!/bin/bash
source .env

# Will run composer in $ZWASTE_INSTALL_PATH
# When de environment is "development" and the correct Composer version is available, it will be run on the host machine,
# otherwise the Composer Docker container will be used
composer_arg=$1
composer_major=$(composer --version | grep -o '[1-9]\.[0-9]\.[0-9]')
composer_major_required="2"
composer="docker compose run --rm composer"
ignore_platform_reqs=""

if [[ "$ENVIRONMENT" == "development" && $composer_major == "$composer_major_required" ]]
then
  composer="composer --working-dir=$ZWASTE_INSTALL_PATH"
  ignore_platform_reqs="--ignore-platform-reqs"
fi

case "$composer_arg" in
  "install")
    $composer install --prefer-dist $ignore_platform_reqs
    echo "-- running 'composer install --prefer-dist $ignore_platform_reqs' --"
  ;;
  "copyenvfor")
    $composer run copyenvfor "$VENDOR" "$ENVIRONMENT"
    echo "-- running 'composer run copyenvfor $VENDOR $ENVIRONMENT' --"
  ;;
  "update")
    $composer update -v
    echo "-- running 'composer update -v' --"
  ;;
esac
