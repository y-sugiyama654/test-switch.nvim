local M = {}

---@class TestSwitch.Rule
---@field from string   ファイルの絶対パスにマッチさせる Lua パターン
---@field to string[]   切り替え先の候補。%1, %2 ... で from のキャプチャを参照する

---@class TestSwitch.Config
---@field create? boolean               切り替え先が存在しないとき新規作成するか
---@field rules? TestSwitch.Rule[]      デフォルトのルールを丸ごと置き換える
---@field extra_rules? TestSwitch.Rule[] デフォルトのルールより優先して評価するルール

-- ルールは上から順に評価し、最初にマッチしたものを使う。
-- そのため「テスト → 実装」のルールを「実装 → テスト」より先に並べる。
---@type TestSwitch.Config
M.defaults = {
  create = true,
  rules = {
    -- Go
    { from = "^(.+)_test%.go$", to = { "%1.go" } },
    { from = "^(.+)%.go$", to = { "%1_test.go" } },

    -- JS/TS: __tests__/ 配下のテスト → 1つ上のディレクトリの実装
    { from = "^(.+)/__tests__/([^/]+)%.test%.([jt]sx?)$", to = { "%1/%2.%3" } },
    { from = "^(.+)/__tests__/([^/]+)%.([jt]sx?)$", to = { "%1/%2.%3" } },

    -- JS/TS: 同じディレクトリの .test / .spec → 実装
    { from = "^(.+)%.test%.([jt]sx?)$", to = { "%1.%2" } },
    { from = "^(.+)%.spec%.([jt]sx?)$", to = { "%1.%2" } },

    -- JS/TS: 実装 → テスト（存在するものを先頭から探す）
    {
      from = "^(.+)/([^/]+)%.([jt]sx?)$",
      to = { "%1/%2.test.%3", "%1/%2.spec.%3", "%1/__tests__/%2.test.%3" },
    },
  },
}

return M
