SHELL:=/bin/bash

.DEFAULT_GOAL := help
.SILENT:

## Colors
COLOR_RESET   = \033[0m
COLOR_INFO    = \033[32m
COLOR_COMMENT = \033[33m

## Help
help:
	printf "${COLOR_COMMENT}Usage:${COLOR_RESET}\n"
	printf " make [target]\n"
	printf " make [target] [args]\n\n"
	printf "${COLOR_COMMENT}Available targets:${COLOR_RESET}\n"
	awk '/^[a-zA-Z\-\\_0-9\.@]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf " ${COLOR_INFO}%-24s${COLOR_RESET} %s\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)

init: clean
	@mkdir .tmp/;

init-web: clean-web
	@git clone git@github.com:trento-project/web.git .tmp/web;

init-wanda: clean-wanda
	@git clone git@github.com:trento-project/wanda.git .tmp/wanda;

clean-web:
	rm -fr .tmp/web

clean-wanda:
	rm -fr .tmp/wanda

clean-scenarios:
	rm -rf ./data/photofinish/*
	rm -rf ./data/photofinish/.photofinish.toml

clean-catalog:
	rm -rf ./data/catalog/*

clean-facts-gathering:
	rm -rf ./data/facts-gathering/*

## Cleans up local setup
clean: clean-scenarios clean-catalog clean-facts-gathering
	rm -rf ./.tmp/

## Prepares photofinish scenarios
get-scenarios: clean-scenarios init-web
	@mv .tmp/web/.photofinish.toml ./data/photofinish/; \
	mkdir -p ./data/photofinish/test/fixtures/scenarios/ && mv .tmp/web/test/fixtures/scenarios/* ./data/photofinish/test/fixtures/scenarios/; \

## Prepares Checks catalog
get-catalog: clean-catalog init-wanda
	@mv .tmp/wanda/priv/catalog/* ./data/catalog/;

## Prepares fake facts configuration
get-facts-config: clean-facts-gathering init-wanda
	@mv .tmp/wanda/priv/demo/fake_facts.yaml ./data/facts-gathering/;

## Starts containers
start: get-scenarios get-catalog get-facts-config
	@docker compose up -d

## Loads default photofinish scenario healthy-27-node-SAP-cluster
load-default-scenario:
	@make load-scenario scenario=healthy-27-node-SAP-cluster

## Loads a specific photofinish scenario by name. Usage: make load-scenario scenario=<scenario-name>
load-scenario:
	@cd ./data/photofinish/ && docker run -v ./:/data --network host ghcr.io/trento-project/photofinish run $(scenario) -u http://localhost:4000/api/collect