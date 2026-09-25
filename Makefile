NVIM ?= nvim
NVIM_TEST = $(NVIM) --headless --noplugin -u scripts/minimal_init.lua

.PHONY: test test-file

# すべてのテストを実行: make test
test: deps/mini.test
	$(NVIM_TEST) -c "lua MiniTest.run()"

# 1ファイルだけ実行: make test-file FILE=tests/test_switch.lua
test-file: deps/mini.test
	$(NVIM_TEST) -c "lua MiniTest.run_file('$(FILE)')"

deps/mini.test:
	@mkdir -p deps
	git clone --filter=blob:none https://github.com/nvim-mini/mini.test $@
