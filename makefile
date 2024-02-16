#!make
include .env
PROJ_INSTALL_PATH := $(ZWASTE_INSTALL_PATH)
ZWASTE_ENV_PATH := $(PROJ_INSTALL_PATH)/.env

.DEFAULT_GOAL := all

.PHONY: all update-env install migrate seed clean user-deny-install-dir user-confirm-install-dir exit \
--msg-install --msg-install-end --msg-self-signed-cert --msg-opzet-dir --msg-copyenvfor --msg-update-env --msg-seed \
--msg-migrate --msg-empty-install-dir --msg-user-deny-install-dir --msg-install-init --msg-install-end --msg-clean

all:
ifeq ($(PROJ_INSTALL_PATH),)
all: --msg-empty-install-dir exit
install: --msg-empty-install-dir exit
else
all: install seed
install: --msg-install user-confirm-install-dir .docker/httpd/cert/httpd-self-signed.cert update-env --msg-install-init
	docker compose run --rm composer install --prefer-dist
	docker compose run --rm npm ci
	@--msg-install-end
endif

.docker/httpd/cert/httpd-self-signed.cert: --msg-self-signed-cert
	@openssl req \
		-new \
		-newkey rsa:4096 \
		-days 365 \
		-nodes \
		-x509 \
		-subj "/C=NL/ST=Noord-Holland/L=Santpoort-Zuid/O=Opzet/CN=$(DOMAIN)" \
		-keyout .docker/httpd/cert/httpd-self-signed.key \
		-out .docker/httpd/cert/httpd-self-signed.cert

$(PROJ_INSTALL_PATH)/opzet: --msg-opzet-dir
	mkdir -p $(PROJ_INSTALL_PATH)
	mkdir logs
	svn checkout $(SVN_INSTALL_BRANCH_URL) $(PROJ_INSTALL_PATH)

$(PROJ_INSTALL_PATH)/.env: $(PROJ_INSTALL_PATH)/opzet --msg-copyenvfor
	docker compose run --rm composer run copyenvfor $(VENDOR) $(ENVIRONMENT)

update-env: $(PROJ_INSTALL_PATH)/.env --msg-update-env
	sed -i "" "s/^DB_HOST=.*/DB_HOST=$(MYSQL_SERVICE_NAME)/" $(ZWASTE_ENV_PATH)

user-deny-install-dir: --msg-user-deny-install-dir exit

exit:
	@exit 1;

user-confirm-install-dir:
	@while [ -z "$$INSTALL_PATH_OK" ]; do \
    	read -r -p "Your install path is: [ $(PROJ_INSTALL_PATH) ], continue installation (Y/n)? " INSTALL_PATH_OK;\
    done ; \
    if [ $$INSTALL_PATH_OK == "n" ]; then \
		$(MAKE) user-deny-install-dir ; \
    fi

seed: migrate --msg-seed
	docker compose run --rm artisan db:seed
	docker compose run --rm artisan script:run scripts/init_opzet.script

migrate: --msg-migrate
	docker compose run --rm artisan config:cache
	docker compose run --rm artisan migrate

clean: --msg-clean
	-@rm -rf logs
	-@rm .docker/httpd/cert/*
	-@sed -i "" "s/^DB_HOST=$(MYSQL_SERVICE_NAME)/DB_HOST=localhost/" $(ZWASTE_ENV_PATH)
	-docker compose down
	-docker compose rm -vf
	-docker image prune -af
	-docker volume prune -af

--msg-self-signed-cert:
	@echo
	@echo "┌─ .DOCKER/NGINX/NGINX-SELF-SIGNED.CERT ───────────────────────────┐"
	@echo "│  Create self signed certificate and key in '.docker/httpd/cert'  │"
	@echo "└──────────────────────────────────────────────────────────────────┘"
	@echo

--msg-opzet-dir:
	@echo
	@echo "┌─ SRC/PUBLIC ──────────────────────────┐"
	@echo "│  Install the zWaste project from SVN  │"
	@echo "└───────────────────────────────────────┘"
	@echo

--msg-copyenvfor:
	@echo
	@echo "┌─ SRC/.ENV ─────────────────────────────────────────────────────────────┐"
	@echo "│  Create src/.env file for vendor: [$(VENDOR)] environment: [$(ENVIRONMENT)] │"
	@echo "└────────────────────────────────────────────────────────────────────────┘"
	@echo

--msg-update-env:
	@echo
	@echo "┌─ UPDATE-ENV ────────────────────────────────────────────────┐"
	@echo "│  Change src/.env DB_HOST to the Docker Compose service name │"
	@echo "└─────────────────────────────────────────────────────────────┘"
	@echo
	@echo "-- Update src/.env DB_HOST value to match the docker container name --"

--msg-seed:
	@echo
	@echo "┌─ SEED ────────────────────────────────────┐"
	@echo "│  Seed the database with some useful data  │"
	@echo "└───────────────────────────────────────────┘"
	@echo

--msg-migrate:
	@echo
	@echo "┌─ MIGRATE ──────────────┐"
	@echo "│  Migrate the database  │"
	@echo "└────────────────────────┘"
	@echo

--msg-install:
	@echo
	@echo "┌─ INSTALL-START ────────────────────────────┐"
	@echo "│  Start installation of the zWaste project  │"
	@echo "└────────────────────────────────────────────┘"

--msg-empty-install-dir:
	@echo
	@echo "┌─ ERROR ──────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  'ZWASTE_INSTALL_PATH' is empty, please edit your .env file to provide a valid path  │"
	@echo "└──────────────────────────────────────────────────────────────────────────────────────┘"

--msg-user-deny-install-dir:
	@echo
	@echo "┌─ ABORTED ────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  You can change the install path by editing 'ZWASTE_INSTALL_PATH' in your .env file  │"
	@echo "└──────────────────────────────────────────────────────────────────────────────────────┘"

--msg-install-init:
	@echo
	@echo "┌─ INSTALL-INIT ────────────────────────┐"
	@echo "│  Run 'composer install' and 'npm ci'  │"
	@echo "└───────────────────────────────────────┘"
	@echo

--msg-install-end:
	@echo
	@echo "┌─ INSTALL-FINISH ──────────────────────────────┐"
	@echo "│  Finished installation of the zWaste project  │"
	@echo "└───────────────────────────────────────────────┘"
	@echo
	@(echo >/dev/tcp/localhost/443) &>/dev/null && echo "HTTPD active on https://$(DOMAIN)" || echo "HTTPD inactive"
	@(echo >/dev/tcp/localhost/3306) &>/dev/null && echo "MySQL active on $(DOMAIN):3306" || echo "MySQL inactive"
	@(echo >/dev/tcp/localhost/8025) &>/dev/null && echo "Mailhog active on http://$(DOMAIN):8025" || echo "Mailhog inactive"

--msg-clean:
	@echo
	@echo "┌─ CLEAN ───────────────────────────────────────────────────────────────────────────────────┐"
	@echo "│  Clean up containers, images, certificates, .env file, and revert docker-compose changes  │"
	@echo "└───────────────────────────────────────────────────────────────────────────────────────────┘"
	@echo
