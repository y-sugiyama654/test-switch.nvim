# test-switch.nvim

[![test](https://github.com/y-sugiyama654/test-switch.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/y-sugiyama654/test-switch.nvim/actions/workflows/test.yml)

English | [日本語](README.ja.md)

Jump between an implementation file and its test file with a single command.

```
pkg/user.go      <->  pkg/user_test.go
src/api.ts       <->  src/api.test.ts / src/api.spec.ts / src/__tests__/api.test.ts
```

## Features

- Toggle between implementation and test files with `:TestSwitch`
- Open the counterpart in the current window, a split, a vertical split, or a new tab
- If the counterpart does not exist yet, open a new buffer for it (the parent directory is created for you)
- When there are several possible test files, pick one with `vim.ui.select`
- Rules are plain [Lua patterns](https://www.lua.org/manual/5.1/manual.html#5.4.1), so adding a language takes two lines

## Requirements

- Neovim >= 0.10

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "y-sugiyama654/test-switch.nvim",
  cmd = "TestSwitch",
  keys = {
    { "<leader>tj", "<cmd>TestSwitch<cr>", desc = "Switch Test/Impl" },
    { "<leader>tJ", "<cmd>TestSwitch vsplit<cr>", desc = "Switch Test/Impl (vsplit)" },
  },
  opts = {},
}
```

Calling `setup()` is optional. The `:TestSwitch` command is available as soon as the plugin is loaded, using the default settings.

## Usage

| Command | Description |
|---|---|
| `:TestSwitch` | Open the counterpart in the current window |
| `:TestSwitch split` | Open it in a horizontal split |
| `:TestSwitch vsplit` | Open it in a vertical split |
| `:TestSwitch tabedit` | Open it in a new tab |

You can also call it from Lua:

```lua
require("test-switch").switch("vsplit")
```

### How the target is chosen

1. Rules are checked from top to bottom. The first rule whose `from` pattern matches the current file is used.
2. Among its `to` candidates, the first file that exists is opened.
3. If none of them exist and `create = true`:
   - with one candidate, a new buffer for it is opened
   - with several candidates, you choose one with `vim.ui.select`

New buffers are not written to disk until you save them.

## Default rules

| Language | Implementation | Test |
|---|---|---|
| Go | `foo.go` | `foo_test.go` |
| JavaScript / TypeScript (`.js` `.jsx` `.ts` `.tsx`) | `foo.ts` | `foo.test.ts`, `foo.spec.ts`, `__tests__/foo.test.ts` |

## Configuration

Default options:

```lua
require("test-switch").setup({
  -- Open a new buffer when the counterpart does not exist
  create = true,
  -- Rules checked before the default rules
  extra_rules = {},
  -- Setting this replaces the default rules entirely
  -- rules = { ... },
})
```

### Writing rules

A rule has two fields:

- `from`: a Lua pattern matched against the absolute path of the current file
- `to`: a list of candidate paths. `%1`, `%2`, ... refer to the captures in `from`

Rules are checked in order, so put the "test → implementation" rule before the "implementation → test" rule. Otherwise the more general pattern also matches test files.

Python (pytest):

```lua
opts = {
  extra_rules = {
    { from = "^(.+)/test_([^/]+)%.py$", to = { "%1/%2.py" } },
    { from = "^(.+)/([^/]+)%.py$", to = { "%1/test_%2.py" } },
  },
}
```

Lua (`lua/foo/bar.lua` <-> `tests/foo/bar_spec.lua`):

```lua
opts = {
  extra_rules = {
    { from = "^(.+)/tests/(.+)_spec%.lua$", to = { "%1/lua/%2.lua" } },
    { from = "^(.+)/lua/(.+)%.lua$", to = { "%1/tests/%2_spec.lua" } },
  },
}
```

## Development

Tests use [mini.test](https://github.com/nvim-mini/mini.test). It is cloned into `deps/` on the first run.

```sh
make test                                   # run all tests
make test-file FILE=tests/test_switch.lua   # run a single file
```

## License

[MIT](LICENSE)
