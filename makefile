# Makefile for npm command line packages 
# (c) 2013 - Vittorio Zaccaria, all rights reserved


BUILD_DIR=./build
DEPLOY_DIR=.
BIN_DIR=$(DEPLOY_DIR)/bin
LIB_DIR=$(DEPLOY_DIR)/lib
EXAMPLES_DIR=$(DEPLOY_DIR)/examples


TARGETS= \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/sk.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/sk-lib.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/tunnel.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/jekyll.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/syslog.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/print.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/actions.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/ssh.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/test.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/connect.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/task.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/config-search.ls)))) \
	$(strip $(patsubst %, $(BUILD_DIR)/%, $(patsubst %.ls, %.js, $(notdir ./src/config.ls)))) 

all: deploy

# Deploy files
.PHONY: _postdeploy
_postdeploy: 
	echo "#!/usr/bin/env node" > $(BIN_DIR)/sk
	cat $(LIB_DIR)/sk.js >> $(BIN_DIR)/sk
	chmod a+rx $(BIN_DIR)/sk
	cp $(LIB_DIR)/config.js $(EXAMPLES_DIR)
	cp $(LIB_DIR)/config.js ~/.sk-files

#### DO NOT MODIFY DOWN HERE..



# Create temporary directories
.PHONY: pre-build
pre-build: 
	mkdir -p $(BUILD_DIR) 

.PHONY: pre-deploy
pre-deploy: clean
	mkdir -p $(BIN_DIR)
	mkdir -p $(LIB_DIR)
	mkdir -p $(EXAMPLES_DIR)


# Deploy files
.PHONY: _deploy
_deploy: 
	 for i in $(TARGETS); do \
		 install -m 755 $$i $(LIB_DIR); \
	 done 

# Runs task build
.PHONY: build
build: 
	 make pre-build
	 make _build


_build:	$(TARGETS)  

# Runs task deploy
.PHONY: deploy
deploy: 
	 make pre-deploy
	 make build
	 make _deploy
	 make _postdeploy

# Vpath definition
VPATH =  \
	$(dir ./src/sk.ls)


# Converting from ls to js
./build/%.js: %.ls
	 lsc --output $(BUILD_DIR) -c $<

# Converting from coffee to js
./build/%.js: %.coffee
	 coffee -b --output $(BUILD_DIR) $<

# Converting from js to js
./build/%.js: %.js
	 cp $< $@

.PHONY: clean
clean:
	rm -f $(LIB_DIR)/*
	rm -f $(BIN_DIR)/*
	rm -f $(BUILD_DIR)/*
	rm -f $(EXAMPLES_DIR)/*

.PHONY: test 
test: deploy
	mocha lib/test.js -R spec -t 1000

dev:
	watchman ./src 'make test' &

