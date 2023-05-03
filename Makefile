ZIP_NAME ?= "DefaultValuesFromPool.zip"
PLUGIN_NAME = default-values-from-pool

COFFEE_FILES =  \
	field-definitor-base-config.coffee \
	pool-manager-default-values.coffee \
	mask-splitter-default-values.coffee

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build zip ## build and zip

build: clean ## build plugin

	mkdir -p build
	mkdir -p build/$(PLUGIN_NAME)
	mkdir -p build/$(PLUGIN_NAME)/webfrontend
	mkdir -p build/$(PLUGIN_NAME)/l10n

	mkdir -p src/tmp # build code from coffee
	cp src/webfrontend/*.coffee src/tmp
	cd src/tmp && coffee -b --compile ${COFFEE_FILES} # bare-parameter is obligatory!
	cat src/tmp/*.js > build/$(PLUGIN_NAME)/webfrontend/default-values-from-pool.js
	rm -rf src/tmp # clean tmp

	cp src/webfrontend/css/default-values-from-pool.css build/$(PLUGIN_NAME)/webfrontend/default-values-from-pool.css # copy css

	cp l10n/default-values-from-pool.csv build/$(PLUGIN_NAME)/l10n/default-values-from-pool.csv # copy l10n

	cp manifest.master.yml build/$(PLUGIN_NAME)/manifest.yml # copy manifest

clean: ## clean
				rm -rf build

zip: build ## zip file
			cd build && zip ${ZIP_NAME} -r $(PLUGIN_NAME)/
