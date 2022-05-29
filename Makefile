# Static ———————————————————————————————————————————————————————————————————————————————————————————————————————————————
LC_LANG = it_IT

# Setup ————————————————————————————————————————————————————————————————————————————————————————————————————————————————
docker := docker-compose
docker_exec := docker-compose exec
php_container := php-fpm
phpstan_container := phpstan
phpcs_container := phpcs
compose	:= $(docker) --file docker-compose.yml
node_container := nodejs
args = $(filter-out $@,$(MAKECMDGOALS))
bin_console := $(docker_exec) $(php_container) php bin/console

start: ## Start all project containers
	$(compose) start
.PHONY: start

stop: ## Stop the project containers
	$(compose) stop $(s)
.PHONY: stop

build: prepare ## Build project images
	$(compose) build
.PHONY: build

up: ## Spin up project containers
	$(compose) up -d --remove-orphans
.PHONY: up

enter: ## Enter the PHP container in bash mode
	$(docker_exec) $(php_container) zsh
.PHONY: enter

erase: ## Erase containers with related volumes
	$(compose) down -v
.PHONY: erase

prepare: hooks ## Prepare the dev environment
	@test -s docker-compose.override.yml || cp docker-compose.override.dist.yml docker-compose.override.yml
.PHONY: prepare

.PHONY: hooks
hooks: ## Add functions to Git hooks
	@rm -rf .git/hooks && ln -s ../.docker/scripts/git-hooks .git/hooks

schema-validate: ## Validate ORM schema
	$(compose) exec -T $(php_container) php bin/console d:s:v
.PHONY: schema-validate

migration: ## Generates a progressive migration
	$(docker_exec) $(php_container) php bin/console make:migration
	make db-reset
.PHONY: migration

db-reset: ## Resets and recreate development db
	$(docker_exec) $(php_container) php bin/console doctrine:database:drop --force --if-exists
	$(docker_exec) $(php_container) php bin/console doctrine:database:create
	$(docker_exec) $(php_container) php bin/console doctrine:schema:update --force
.PHONY: db-create

db-reset-test: ## Resets and recreate test db
	$(docker_exec) $(php_container) php bin/console doctrine:database:drop --force --if-exists --env=test
	$(docker_exec) $(php_container) php bin/console doctrine:database:create --env=test
	$(docker_exec) $(php_container) php bin/console doctrine:schema:create --env=test
.PHONY: db-reset-test

init-db:
	@if [ "$$CI" != "" ] || ([ -d /proc ] && ([ "$$(grep docker /proc/1/cgroup)" != "" ] || [ "$$(grep kubepods /proc/1/cgroup)" != "" ])); then \
		php bin/console doctrine:database:drop --force --if-exists; \
        php bin/console doctrine:database:create; \
        php bin/console doctrine:schema:create; \
	else \
		$(docker_exec) -e APP_ENV -e TEST_TOKEN $(php_container) php bin/console doctrine:database:drop --force --if-exists; \
        $(docker_exec) -e APP_ENV -e TEST_TOKEN $(php_container) php bin/console doctrine:database:create; \
        $(docker_exec) -e APP_ENV -e TEST_TOKEN $(php_container) php bin/console doctrine:schema:create; \
	fi
.PHONY: init-db

test: export APP_ENV = test
test: export APP_DEBUG = 1
test:
	make clear-cache
	make init-db
	@if [ "$$CI" != "" ] || ([ -d /proc ] && ([ "$$(grep docker /proc/1/cgroup)" != "" ] || [ "$$(grep kubepods /proc/1/cgroup)" != "" ])); then \
		vendor/bin/phpunit --configuration phpunit.xml.dist --stop-on-failure --coverage-clover phpunit/phpunit.coverage.xml --log-junit phpunit/junit.xml; \
	else \
		$(docker_exec) -e APP_ENV -e APP_DEBUG $(php_container) vendor/bin/phpunit --configuration phpunit.xml.dist --testdox --stop-on-failure $(call args); \
	fi
.PHONY: test

test-coverage: export APP_ENV = test
test-coverage: export APP_DEBUG = 1
test-coverage:
	make clear-cache
	make init-db
	rm -rf coverage-report
	$(docker_exec) -e APP_ENV -e APP_DEBUG $(php_container) vendor/bin/phpunit --configuration phpunit.xml.dist --stop-on-failure --coverage-html coverage-report $(call args)
.PHONY: test-coverage

infection: export APP_ENV = test
infection: export APP_DEBUG = 1
infection:
	make clear-cache
	make init-db
	@if [ "$$CI" != "" ] || ([ -d /proc ] && ([ "$$(grep docker /proc/1/cgroup)" != "" ] || [ "$$(grep kubepods /proc/1/cgroup)" != "" ])); then \
		wget https://github.com/infection/infection/releases/download/0.26.8/infection.phar ; \
		chmod +x infection.phar ; \
  		php infection.phar --only-covered --threads=4; \
	else \
		$(docker_exec) -e APP_ENV -e APP_DEBUG $(php_container) infection --only-covered --threads=4  $(call args); \
	fi
.PHONY: infection

phpstan:
	@if [ "$$CI" != "" ] || ([ -d /proc ] && ([ "$$(grep docker /proc/1/cgroup)" != "" ] || [ "$$(grep kubepods /proc/1/cgroup)" != "" ])); then \
		phpstan analyse src/ -c phpstan.neon --level=8 --no-progress -vvv --memory-limit=2048M; \
	else \
		$(docker_exec) $(phpstan_container) phpstan analyse src/ -c phpstan.neon --level=8 --no-progress -vvv --memory-limit=2048M; \
	fi
.PHONY: phpstan

csfix:
	$(docker_exec) $(phpcs_container) phpcbf src/ tests/
.PHONY: csfix

cscheck:
	@if [ "$$CI" != "" ] || ([ -d /proc ] && ([ "$$(grep docker /proc/1/cgroup)" != "" ] || [ "$$(grep kubepods /proc/1/cgroup)" != "" ])); then \
		phpcs src/; \
	else \
		$(docker_exec) $(phpcs_container) phpcs src/; \
	fi
.PHONY: cscheck

precommit: schema-validate ## Exec actions before commit files
	$(compose) exec -T $(php) vendor/bin/phpcs src/
	$(compose) exec -T $(php_container) vendor/bin/phpstan analyse src/ -c phpstan.neon --level=8 --no-progress -vvv --memory-limit=2048M
.PHONY: precommit

.PHONY: commitlint
commitlint: ## Verify commit title
		$(compose) run --rm $(node_container) sh -lc 'commitlint -e --from=HEAD'

bin-console:
	$(bin_console) $(call args)
.PHONY: bin-console

clear-cache:
	@if [ "$$CI" != "" ] || ([ -d /proc ] && ([ "$$(grep docker /proc/1/cgroup)" != "" ] || [ "$$(grep kubepods /proc/1/cgroup)" != "" ])); then \
		php bin/console cache:pool:clear cache.global_clearer ;\
        php bin/console cache:clear --no-warmup ;\
        php bin/console cache:warmup ;\
	else \
		$(docker_exec) -e APP_ENV $(php_container) php bin/console cache:pool:clear cache.global_clearer ;\
        $(docker_exec) -e APP_ENV $(php_container) php bin/console cache:clear --no-warmup ;\
        $(docker_exec) -e APP_ENV $(php_container) php bin/console cache:warmup ;\
	fi
.PHONY: clear-cache

load-fixtures:
		$(docker_exec) $(php_container) php bin/console doctrine:database:drop --force --if-exists; \
        $(docker_exec) $(php_container) php bin/console doctrine:database:create; \
        $(docker_exec) $(php_container) php bin/console doctrine:schema:create; \
        $(docker_exec) $(php_container) php bin/console doctrine:fixtures:load -n -vvv;
.PHONY: load-fixtures

security-check:
	$(docker_exec) $(php_container) symfony security:check
.PHONY: security-check

testsuite: export APP_ENV = test
testsuite: export APP_DEBUG = 1
testsuite:
	make clear-cache ; \
    make load-fixtures ; \
    bin/phpunit $(RUN_ARGS) ; \
    bin/phpunit $(RUN_ARGS) ;
.PHONY: testsuite

.PHONY: help
help: ## Show available commands list
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
