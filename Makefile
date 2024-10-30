#!make
ENV?=.env

.DEFAULT_GOAL := all
all: set-up-workspace copyenvfor update-env composer-install npm-ci
m: all migrate
m-s: all migrate seed

set-up-workspace:
	@ENV=$(ENV) sh/step-1-set-up-workspace.sh

copyenvfor:
	@ENV=$(ENV) ./sh/step-2-copyenvfor.sh

update-env:
	@ENV=$(ENV) ./sh/step-3-update-env.sh

composer-install:
	@ENV=$(ENV) ./sh/step-4-composer-install.sh

npm-ci:
	@ENV=$(ENV) ./sh/step-5-npm-ci.sh

migrate:
	@ENV=$(ENV) ./sh/step-6-artisan-migrate.sh

seed:
	@ENV=$(ENV) ./sh/step-7-artisan-seed.sh

finish:
	@ENV=$(ENV) ./sh/step-8-install-finish.sh

down:
	docker compose down

switch:
	cp -f ".env.${ENV}" .env
