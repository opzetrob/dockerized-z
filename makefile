#!make
include .env
MYSQL_CONTAINER := mysql
DISALLOW_INSECURE_DEV_DOMAIN := 1
CAN_CLEAN_PROMPT ?= $(shell bash -c 'read -p "Warning! Clean will remove the zWaste project! Continue (y/N)?: " CAN_CLEAN; echo $$CAN_CLEAN')

.DEFAULT_GOAL := all
.PHONY: all clean include-env seed install sync-configs

all: install seed

src/public:
	@echo
	@echo "┌─ SRC/PUBLIC ──────────────────────────┐"
	@echo "│  Install the zWaste project from SVN  │"
	@echo "└───────────────────────────────────────┘"
	@echo
	svn checkout $(INSTALL_BRANCH_URL) src

src/.env: src/public
	@echo
	@echo "┌─ SRC/.ENV ─────────────────────────────────────────────────────────────┐"
	@echo "│  Create src/.env file for vendor: [$(VENDOR)] environment: [$(ENVIRONMENT)] │"
	@echo "└────────────────────────────────────────────────────────────────────────┘"
	@echo
	docker compose run --rm composer run copyenvfor $(VENDOR) $(ENVIRONMENT)

.docker/httpd/cert/httpd-self-signed.cert:
	@echo
	@echo "┌─ .DOCKER/NGINX/NGINX-SELF-SIGNED.CERT ───────────────────────────┐"
	@echo "│  Create self signed certificate and key in '.docker/httpd/cert'  │"
	@echo "└──────────────────────────────────────────────────────────────────┘"
	@echo
	@openssl req \
		-new \
		-newkey rsa:4096 \
		-days 365 \
		-nodes \
		-x509 \
		-subj "/C=NL/ST=Noord-Holland/L=Santpoort-Zuid/O=Opzet/CN=$(DOMAIN)" \
		-keyout .docker/httpd/cert/httpd-self-signed.key \
		-out .docker/httpd/cert/httpd-self-signed.cert

sync-configs: src/.env
	@echo
	@echo "┌─ SYNC-CONFIGS ────────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  Sync some variables in docker-compose.yml, src/.env, src/composer.json and src/composer.lock │"
	@echo "└───────────────────────────────────────────────────────────────────────────────────────────────┘"
	@echo
	sed -i "" "s/MYSQL_DATABASE: .*/MYSQL_DATABASE: zcalendar/" "docker-compose.yml"
	sed -i "" "s/MYSQL_USER: .*/MYSQL_USER: zcalendar/" "docker-compose.yml"
	sed -i "" "s/MYSQL_PASSWORD: .*/MYSQL_PASSWORD: zcalendar/" "docker-compose.yml"
	sed -i "" "s|image: mailhog/mailhog:latest|image: jcalonso/mailhog:latest|" "docker-compose.yml"
	@echo "-- Update src/.env DB_HOST value to match the docker container name --"
	sed -i "" "s/^DB_HOST=.*/DB_HOST=$(MYSQL_CONTAINER)/" "src/.env"
    ifneq (0,$(DISALLOW_INSECURE_DEV_DOMAIN))
	sed -i "" "s|http://svn.loki.dev|http://192.168.0.26|" "src/composer.json"
	sed -i "" "s|http://svn.loki.dev|http://192.168.0.26|" "src/composer.lock"
    endif

install: .docker/httpd/cert/httpd-self-signed.cert src/.env sync-configs
	@echo
	@echo "┌─ INSTALL ───────────────────────┐"
	@echo "│  Install zWaste in 'src'        │"
	@echo "└─────────────────────────────────┘"
	@echo
	docker compose run --rm composer install --prefer-dist
	docker compose run --rm npm ci

seed:
	@echo
	@echo "┌─ SEED ──────────────────────────┐"
	@echo "│  Migrate and seed the database  │"
	@echo "└─────────────────────────────────┘"
	@echo
	docker compose run --rm artisan config:cache
	docker compose run --rm artisan migrate
	docker compose run --rm artisan db:seed

include-env:
	@echo
	@echo "┌─ INCLUDE-ENV ───────────────────────────────────────────────────┐"
	@echo "│  Make the values in src/.env available for use in the Makefile  │"
	@echo "└─────────────────────────────────────────────────────────────────┘"
	@echo
	include src/.env
	export

clean:
	@echo
	@echo "┌─ CLEAN ───────────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  Clean up containers, images, certificates, .env file, and revert docker-compose changes  │"
	@echo "└───────────────────────────────────────────────────────────────────────────────────────────┘"
	@echo
ifndef ENV_VAR
	@echo Warning: "This will remove all code from 'src/'; continue? [y/N]"
	@read line; if [ $$line != "y" ]; then echo Aborted; exit 1 ; fi
endif
	-rm -rf src
	-rm -rf logs
	mkdir src
	-rm .docker/httpd/cert/*
	sed -i "" "s/MYSQL_DATABASE: .*/MYSQL_DATABASE: homestead/" "docker-compose.yml"
	sed -i "" "s/MYSQL_USER: .*/MYSQL_USER: homestead/" "docker-compose.yml"
	sed -i "" "s/MYSQL_PASSWORD: .*/MYSQL_PASSWORD: secret/" "docker-compose.yml"
	sed -i "" "s|image: jcalonso/mailhog:latest|image: mailhog/mailhog:latest|" "docker-compose.yml"
	docker compose down
	docker image prune -f
	docker rmi -f z-waste-httpd:latest

