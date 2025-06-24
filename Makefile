#!make
ENV?=.env
SHENV = ENV=$(ENV)
COMPOSE_FILE ?= docker-compose.yml

.PHONY: all m m-s _set-up-workspace _copyenvfor _update-env composer-install npm-ci migrate seed _finish down start switch active
.DEFAULT_GOAL := all
all: _set-up-workspace _copyenvfor _update-env composer-install npm-ci _finish
m: all migrate
m-s: all migrate seed

_set-up-workspace:
	@$(SHENV) ./sh/step-1-set-up-workspace.sh

_copyenvfor:
	@$(SHENV) ./sh/step-2-copyenvfor.sh

_update-env:
	@$(SHENV) ./sh/step-3-update-env.sh

composer-install: ## Run `composer install` in the container
	@$(SHENV) ./sh/step-4-composer-install.sh

npm-ci: ## Run `npm ci`in the container
	@$(SHENV) ./sh/step-5-npm-ci.sh

migrate: ## Run `artisan migrate` in the container
	@$(SHENV) ./sh/step-6-artisan-migrate.sh

seed: ## Run `artisan seed` in the container
	@$(SHENV) ./sh/step-7-artisan-seed.sh

_finish:
	@$(SHENV) ./sh/step-8-install-finish.sh

down: ## Bring down all project containers
	docker compose --file "${COMPOSE_FILE}" down

start: _set-up-workspace ## Start the current project and display project name
	@set -a; . $(ENV); set +a; echo "started project: $$CLIENT_NAME"

switch: ## Replace the contents of `.env` by those of `.env.{CLIENT_NAME}`
	cp -f ".env.${ENV}" .env

active: ## Show active project and install path
	@set -a; . $(ENV); set +a; echo "active project: $$CLIENT_NAME"
	@set -a; . $(ENV); set +a; echo "install path: $$HOST_INSTALL_PATH"

help:
	@echo "Available targets:"
	@awk '/^[a-zA-Z0-9_-]+:.*##/ {printf "  \033[36m%-20s\033[0m %s\n", $$1, substr($$0, index($$0, "##")+3)}' $(MAKEFILE_LIST)
