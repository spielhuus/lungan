SOURCEDIR=lua
SPECDIR=spec
SOURCES := $(shell find $(SOURCEDIR) -name '*.lua')
SPEC_FILES := $(shell find $(SPECDIR) -name '*_spec.lua')
PYTHON=.venv/bin/python
LUAROCKS=luarocks
LUACHECK=luacheck
LUA_PATH=$(shell luarocks --lua-version 5.1 --tree .venv path --lr-path)
LUA_CPATH=$(shell luarocks --lua-version 5.1 --tree .venv path --lr-cpath)
XDG=.venv
XDG_SITE=$(XDG)/local/share/nvim/site/
TEST_PATH=PATH='.venv/bin:$(PATH)' \
	        LUA_PATH='$(LUA_PATH)' \
					LUA_CPATH='$(LUA_CPATH)' \
					XDG_CONFIG_HOME='$(XDG)/config/' \
					XDG_STATE_HOME='$(XDG)/local/state/' \
					XDG_DATA_HOME='$(XDG)/local/share/'

.PHONY: apidoc luacheck docker test clean help

all: $(PYTHON) $(XDG_SITE) test ## Run all the targets

$(PYTHON):
	python -m venv .venv
	.venv/bin/pip install ipython
	.venv/bin/pip install matplotlib

$(XDG_SITE): 
	mkdir -p $(XDG_SITE)/pack/testing/start
	git clone --depth 1 https://github.com/nvim-lua/plenary.nvim \
	                    $(XDG_SITE)/pack/testing/start/plenary.nvim
	git clone --depth 1 https://github.com/nvim-telescope/telescope.nvim \
	                    $(XDG_SITE)/pack/testing/start/telescope
	git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter.git \
	                    $(XDG_SITE)/pack/testing/start/nvim-treesitter
	git clone --depth 1 https://github.com/hrsh7th/nvim-cmp.git \
                      $(XDG_SITE)/pack/testing/start/nvim-cmp

apidoc: ## Create the apidoc
	$(TEST_PATH) nlua scripts/makedoc.lua

luacheck: ## Run luackeck
	$(LUACHECK) lua spec

test: $(XDG_SITE) $(SOURCES) $(PYTHON) ## Run the tests
	$(TEST_PATH) PYTHONPATH=./python3:$(PYTHONPATH) $(LUAROCKS) --lua-version 5.1 --tree .venv test

install: $(SOURCES) $(SPEC_FILES) ## install the lua rock
	$(TEST_PATH) PYTHONPATH=./python3:$(PYTHONPATH) $(LUAROCKS) --lua-version 5.1 --tree .venv make

clean: ## Remove temprorary files
	rm -rf .cache
	rm -rf .local
	rm -rf .luarocks
	rm -rf .bash_history
	rm -rf .wget-hsts
	rm -rf .venv
	rm -rf .ci

help: 
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

luals:
	# rm -rf .ci/lua-ls/log
	lua-language-server --configpath .luarc.json --logpath .ci/lua-ls/log --check .
	# [ -f .ci/lua-ls/log/check.json ] && { cat .ci/lua-ls/log/check.json 2>/dev/null; exit 1; } || true

# luals:
	# mkdir -p .ci/lua-ls
	# curl -sL "https://github.com/LuaLS/lua-language-server/releases/download/3.7.4/lua-language-server-3.7.4-darwin-x64.tar.gz" | tar xzf - -C "${PWD}/.ci/lua-ls"
	# make luals-ci
