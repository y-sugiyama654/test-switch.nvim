# test-switch.nvim

[![test](https://github.com/y-sugiyama654/test-switch.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/y-sugiyama654/test-switch.nvim/actions/workflows/test.yml)

[English](README.md) | 日本語

実装ファイルとテストファイルを、コマンド1つで行き来するための Neovim プラグインです。

```
pkg/user.go      <->  pkg/user_test.go
src/api.ts       <->  src/api.test.ts / src/api.spec.ts / src/__tests__/api.test.ts
```

## 機能

- `:TestSwitch` で実装ファイルとテストファイルを切り替える
- 切り替え先を、今のウィンドウ・水平分割・垂直分割・新しいタブのどれで開くか選べる
- 切り替え先がまだなければ、新しいバッファとして開く（親ディレクトリも作成する）
- テストファイルの候補が複数あるときは、`vim.ui.select` で選べる
- ルールは [Lua パターン](https://www.lua.org/manual/5.1/manual.html#5.4.1)で書くので、2行足すだけで新しい言語に対応できる

## 動作環境

- Neovim 0.10 以上

## インストール

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

`setup()` を呼ばなくても使えます。プラグインが読み込まれた時点で `:TestSwitch` コマンドが使えるようになり、デフォルトの設定で動きます。

## 使い方

| コマンド | 説明 |
|---|---|
| `:TestSwitch` | 今のウィンドウで開く |
| `:TestSwitch split` | 水平分割で開く |
| `:TestSwitch vsplit` | 垂直分割で開く |
| `:TestSwitch tabedit` | 新しいタブで開く |

Lua から呼び出すこともできます。

```lua
require("test-switch").switch("vsplit")
```

### 切り替え先の決まり方

1. ルールを上から順に調べ、`from` のパターンが今のファイルにマッチした最初のルールを使います。
2. そのルールの `to` の候補のうち、存在する最初のファイルを開きます。
3. どの候補も存在せず、`create = true` の場合:
   - 候補が1つなら、そのファイルを新しいバッファとして開きます
   - 候補が複数なら、`vim.ui.select` で選びます

新しいバッファは、保存するまでディスクには書き込まれません。

## デフォルトのルール

| 言語 | 実装 | テスト |
|---|---|---|
| Go | `foo.go` | `foo_test.go` |
| JavaScript / TypeScript（`.js` `.jsx` `.ts` `.tsx`） | `foo.ts` | `foo.test.ts`、`foo.spec.ts`、`__tests__/foo.test.ts` |

## 設定

デフォルトの設定:

```lua
require("test-switch").setup({
  -- 切り替え先がないとき、新しいバッファとして開く
  create = true,
  -- デフォルトのルールより先に調べるルール
  extra_rules = {},
  -- 指定するとデフォルトのルールを丸ごと置き換える
  -- rules = { ... },
})
```

### ルールの書き方

ルールには2つの項目があります。

- `from`: 今のファイルの絶対パスにマッチさせる Lua パターン
- `to`: 切り替え先の候補パスのリスト。`%1`、`%2` … で `from` のキャプチャを参照できる

ルールは上から順に調べるので、「テスト → 実装」のルールを「実装 → テスト」のルールより先に書いてください。逆にすると、より広くマッチするパターンがテストファイルにもマッチしてしまいます。

Python（pytest）:

```lua
opts = {
  extra_rules = {
    { from = "^(.+)/test_([^/]+)%.py$", to = { "%1/%2.py" } },
    { from = "^(.+)/([^/]+)%.py$", to = { "%1/test_%2.py" } },
  },
}
```

Lua（`lua/foo/bar.lua` <-> `tests/foo/bar_spec.lua`）:

```lua
opts = {
  extra_rules = {
    { from = "^(.+)/tests/(.+)_spec%.lua$", to = { "%1/lua/%2.lua" } },
    { from = "^(.+)/lua/(.+)%.lua$", to = { "%1/tests/%2_spec.lua" } },
  },
}
```

## 開発

テストには [mini.test](https://github.com/nvim-mini/mini.test) を使います。初回の実行時に `deps/` に clone されます。

```sh
make test                                   # すべてのテストを実行
make test-file FILE=tests/test_switch.lua   # 1ファイルだけ実行
```

## ライセンス

[MIT](LICENSE)
