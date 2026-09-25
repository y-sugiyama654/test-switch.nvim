-- resolver はエディタの状態に依存しないので、子プロセスを使わずに直接テストする
local new_set, eq = MiniTest.new_set, MiniTest.expect.equality

local rules = require("test-switch.config").defaults.rules
local candidates = require("test-switch.resolver").candidates

local T = new_set()

T["candidates()"] = new_set()

-- parametrize に並べた引数ごとに、同じテストケースが1回ずつ実行される
T["candidates()"]["default rules"] = new_set({
  parametrize = {
    -- Go
    { "/p/pkg/user.go", { "/p/pkg/user_test.go" } },
    { "/p/pkg/user_test.go", { "/p/pkg/user.go" } },
    -- JS/TS: 実装 → テスト
    { "/p/src/user.ts", { "/p/src/user.test.ts", "/p/src/user.spec.ts", "/p/src/__tests__/user.test.ts" } },
    { "/p/src/Button.tsx", { "/p/src/Button.test.tsx", "/p/src/Button.spec.tsx", "/p/src/__tests__/Button.test.tsx" } },
    { "/p/src/util.js", { "/p/src/util.test.js", "/p/src/util.spec.js", "/p/src/__tests__/util.test.js" } },
    -- JS/TS: テスト → 実装
    { "/p/src/user.test.ts", { "/p/src/user.ts" } },
    { "/p/src/user.spec.js", { "/p/src/user.js" } },
    { "/p/src/__tests__/user.test.ts", { "/p/src/user.ts" } },
    { "/p/src/__tests__/user.ts", { "/p/src/user.ts" } },
    -- ドットを含むファイル名
    { "/p/src/user.service.ts", { "/p/src/user.service.test.ts", "/p/src/user.service.spec.ts", "/p/src/__tests__/user.service.test.ts" } },
    { "/p/src/user.service.test.ts", { "/p/src/user.service.ts" } },
    -- 対象外
    { "/p/README.md", {} },
    { "/p/main.gohtml", {} },
  },
})

T["candidates()"]["default rules"]["resolves"] = function(input, expected)
  eq(candidates(input, rules), expected)
end

T["candidates()"]["uses the first matching rule"] = function()
  local custom = {
    { from = "^(.+)%.lua$", to = { "%1_first.lua" } },
    { from = "^(.+)%.lua$", to = { "%1_second.lua" } },
  }
  eq(candidates("/p/a.lua", custom), { "/p/a_first.lua" })
end

T["candidates()"]["returns empty list for no rules"] = function()
  eq(candidates("/p/a.go", {}), {})
end

return T
