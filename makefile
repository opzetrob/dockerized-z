#!make
include .env
PROJ_INSTALL_PATH := $(ZWASTE_INSTALL_PATH)
DOCKER_COMPOSE := docker compose
CERT_PATH := .docker/httpd/cert/
DOMAIN_CERT := $(DOMAIN).pem
DOMAIN_KEY := $(DOMAIN)-key.pem
.DEFAULT_GOAL := all
DOMAIN_IN_HOSTS := $(shell grep -n $(DOMAIN) /etc/hosts | tail -1)
ifeq ($(shell arch),arm64)
	MAILHOG_IMAGE := jcalonso/mailhog
else
	MAILHOG_IMAGE ?= mailhog/mailhog
endif
export

.PHONY: all guard-env update-env install migrate seed clean user-deny-install-dir user-confirm-install-dir exit \
--msg-install --msg-install-end --msg-self-signed-cert --msg-opzet-dir --msg-copyenvfor --msg-update-env --msg-seed \
--msg-migrate --msg-empty-install-dir --msg-user-deny-install-dir --msg-install-init --msg-install-end --msg-clean \
npm

all:
ifeq ($(PROJ_INSTALL_PATH),)
all: --msg-empty-install-dir exit
install: --msg-empty-install-dir exit
else
# Calling 'make' will do a full install and database seed
all: guard-env install seed
# Calling 'make install' will do a full install
# Run Composer install and NPM ci in their respective containers.
# Note: Targets after ':' are >prerequisites<; they will be called >before< the install target is run
install: --msg-install user-confirm-install-dir docker-up update-env --msg-install-init composer-install npm-ci
	@--msg-install-end
endif

# Will check all environment variables provided as prerequisites with the format 'guard-MY_ENV_VAR'
guard-env: | guard-DOMAIN guard-ZWASTE_INSTALL_PATH guard-VENDOR guard-ENVIRONMENT guard-SVN_INSTALL_BRANCH_URL \
guard-SSH_AUTH_SOCK guard-MYSQL_SERVICE_NAME guard-MAILHOG_IMAGE guard-NPM_TOKEN

# Checks if the environment variable can be found and exits when it's missing
guard-%:
	$(eval len := $(shell printf '%s' $(subst ',','.',${*}) | wc -c))
	$(eval run := $(shell printf '─%.0s' {1..$(len)}))
	@if [ "${${*}}" = "" ]; then \
		echo "┌─ MISSING ENV VARIABLE $(run)────────────────────────────────────────────────┐"; \
		echo "│  Missing environment variable '$*', it may be missing from your .env file │"; \
		echo "└──$(run)─────────────────────────────────────────────────────────────────────┘"; \
		exit 1; \
	fi

# Create cert and key .pem files for the domain
# Note: This target refers to a specific file. If the file is found to be present, the target code will >not< run
$(CERT_PATH)$(DOMAIN_CERT): add-hosts --msg-self-signed-cert
	@mkcert -key-file $(CERT_PATH)$(DOMAIN_KEY) -cert-file $(CERT_PATH)$(DOMAIN_CERT) $(DOMAIN)

# Check if a path /opzet exists in the install path and check out the zWaste project from SVN if it doesn't
# Note: This target refers to a specific file. If the file is found to be present, the target code will >not< run
$(PROJ_INSTALL_PATH)/opzet: --msg-opzet-dir
	mkdir -p $(PROJ_INSTALL_PATH)
	svn checkout $(SVN_INSTALL_BRANCH_URL) $(PROJ_INSTALL_PATH)
	-mkdir logs

# Trigger the copyenvfor composer command inside the composer container
# Note: This target refers to a specific file. If the file is found to be present, the target code will >not< run
$(PROJ_INSTALL_PATH)/.env: $(PROJ_INSTALL_PATH)/opzet --msg-copyenvfor composer-copyenvfor

# Adds the domain to the hosts file, you may need to enter your password
add-hosts: --msg-add-hosts
ifeq ($(DOMAIN_IN_HOSTS),)
	$(shell echo '127.0.0.1       $(DOMAIN)' | sudo tee -a /etc/hosts > /dev/null)
endif

# Update the project's .env file to work with a containerized environment
update-env: $(PROJ_INSTALL_PATH)/.env --msg-update-env
	sed -i "" "s/^DB_HOST=.*/DB_HOST=$(MYSQL_SERVICE_NAME)/" $(PROJ_INSTALL_PATH)/.env

# Bring up the http container and it's dependencies
# -d: In detached mode: Run containers in the background
# --build: Build the images used before starting containers
docker-up: $(CERT_PATH)$(DOMAIN_CERT) rebuild --msg-docker-up

# To do a simple `docker compose up` without losing the pem files
rebuild:
	@CERT=$(DOMAIN_CERT) \
	KEY=$(DOMAIN_KEY) \
	MAILHOG_IMAGE=$(MAILHOG_IMAGE) \
	$(DOCKER_COMPOSE) up -d --build httpd

npm:
	@./npm.sh
# Run NPM on it's container or locally, depending on the ENVIRONMENT value
npm-%:
	@./npm.sh ${*}

composer-%:
	@./composer.sh

# User canceled the install - Abort
user-deny-install-dir: --msg-user-deny-install-dir exit

# Exit the make process
exit:
	@false

# Prompt user to confirm the install dir
user-confirm-install-dir:
	@while [ -z "$$INSTALL_PATH_OK" ]; do \
    	read -r -p "Your install path is: [ $(PROJ_INSTALL_PATH) ], continue installation (y/N)? " INSTALL_PATH_OK;\
    done ; \
    if [ $$INSTALL_PATH_OK != "y" ]; then \
		$(MAKE) user-deny-install-dir ; \
    fi

# Seed the database and run the init_opzet script for additional, useful data
seed: migrate --msg-seed
	$(DOCKER_COMPOSE) run --rm artisan db:seed
	$(DOCKER_COMPOSE) run --rm artisan script:run scripts/init_opzet.script

# Clear the cache and perform the migrations
migrate: --msg-migrate
	$(DOCKER_COMPOSE) run --rm artisan config:cache
	$(DOCKER_COMPOSE) run --rm artisan migrate

clean: --msg-clean
	-@rm -rf logs
	-@rm .docker/httpd/cert/*
	-@sed -i "" "s/^DB_HOST=$(MYSQL_SERVICE_NAME)/DB_HOST=localhost/" $(PROJ_INSTALL_PATH)/.env
	-$(DOCKER_COMPOSE) down
	-$(DOCKER_COMPOSE) rm -vf
	-docker image prune -af
	-docker volume prune -af

--msg-self-signed-cert:
	@echo
	@echo "┌─ .DOCKER/NGINX/NGINX-SELF-SIGNED.CERT ───────────────────────────┐"
	@echo "│  Create self signed certificate and key in '.docker/httpd/cert'  │"
	@echo "└──────────────────────────────────────────────────────────────────┘"

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
	@echo "│  Change src/.env DB_HOST to the docker compose service name │"
	@echo "└─────────────────────────────────────────────────────────────┘"
	@echo
	@echo "-- Update src/.env DB_HOST value to match the docker container name --"

--msg-docker-up:
	@echo
	@echo "┌─ DOCKER-UP ────────────────────────────────────────────┐"
	@echo "│  Bringing up the 'httpd' service and it's dependencies │"
	@echo "└────────────────────────────────────────────────────────┘"
	@echo

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

--msg-add-hosts:
	@echo
	@echo "┌─ ADD HOSTS ──────────────────────────────────┐"
	@echo "│  Add the domain to the hosts file if needed  │"
	@echo "└──────────────────────────────────────────────┘"

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
