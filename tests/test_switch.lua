-- switch() はバッファやウィンドウを操作するので、テストごとに子 Neovim を起動し直して
-- 状態が他のテストに漏れないようにする
local new_set, eq = MiniTest.new_set, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local WARN, ERROR = vim.log.levels.WARN, vim.log.levels.ERROR

-- 子プロセス内に、一時ディレクトリとテスト用ヘルパーを用意する
local function setup_child()
  child.lua([[
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, "p")
    -- macOS では /var が /private/var へのシンボリックリンクなので実体パスにそろえる
    _G.root = vim.uv.fs_realpath(dir)

    _G.rel = function(path)
      return (path:gsub("^" .. vim.pesc(root) .. "/", ""))
    end

    _G.touch = function(path)
      local abs = root .. "/" .. path
      vim.fn.mkdir(vim.fs.dirname(abs), "p")
      vim.fn.writefile({}, abs)
    end

    -- vim.notify を差し替えて、通知された内容を記録する
    _G.notifications = {}
    vim.notify = function(msg, level)
      table.insert(notifications, { msg = msg, level = level })
    end

    -- vim.ui.select を差し替えて、index 番目の候補を選んだことにする（範囲外ならキャンセル）
    _G.stub_select = function(index)
      vim.ui.select = function(items, opts, on_choice)
        _G.select_items = vim.tbl_map(rel, items)
        _G.select_prompt = opts.prompt
        on_choice(items[index])
      end
    end
  ]])
end

local touch = function(...)
  for _, path in ipairs({ ... }) do
    child.lua("touch(...)", { path })
  end
end
local edit = function(path)
  child.lua("vim.cmd.edit(vim.fn.fnameescape(root .. '/' .. ...))", { path })
end
local switch = function(cmd)
  child.cmd("TestSwitch" .. (cmd and (" " .. cmd) or ""))
end
local current = function()
  return child.lua_get("rel(vim.api.nvim_buf_get_name(0))")
end
local exists = function(path)
  return child.lua_get("vim.uv.fs_stat(root .. '/' .. ...) ~= nil", { path })
end
local last_notification = function()
  return child.lua_get("notifications[#notifications]")
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "scripts/minimal_init.lua" })
      setup_child()
    end,
    post_once = child.stop,
  },
})

T["switch()"] = new_set()

T["switch()"]["opens existing test file from implementation"] = function()
  touch("pkg/user.go", "pkg/user_test.go")
  edit("pkg/user.go")
  switch()
  eq(current(), "pkg/user_test.go")
end

T["switch()"]["opens existing implementation from test file"] = function()
  touch("pkg/user.go", "pkg/user_test.go")
  edit("pkg/user_test.go")
  switch()
  eq(current(), "pkg/user.go")
end

T["switch()"]["toggles back and forth"] = function()
  touch("src/api.ts", "src/api.test.ts")
  edit("src/api.ts")
  switch()
  switch()
  eq(current(), "src/api.ts")
end

T["switch()"]["prefers the first existing candidate"] = function()
  -- .test.ts は存在せず .spec.ts と __tests__ がある → 候補順で .spec.ts が選ばれる
  touch("src/api.ts", "src/api.spec.ts", "src/__tests__/api.test.ts")
  edit("src/api.ts")
  switch()
  eq(current(), "src/api.spec.ts")
end

T["switch()"]["opens __tests__ file when it is the only one"] = function()
  touch("src/api.ts", "src/__tests__/api.test.ts")
  edit("src/api.ts")
  switch()
  eq(current(), "src/__tests__/api.test.ts")
end

T["switch()"]["open command"] = new_set({
  parametrize = { { "edit", 1, 1 }, { "split", 2, 1 }, { "vsplit", 2, 1 }, { "tabedit", 1, 2 } },
})

T["switch()"]["open command"]["opens in expected layout"] = function(cmd, wins_in_tab, tabs)
  touch("pkg/user.go", "pkg/user_test.go")
  edit("pkg/user.go")
  switch(cmd)
  eq(current(), "pkg/user_test.go")
  eq(child.lua_get("#vim.api.nvim_tabpage_list_wins(0)"), wins_in_tab)
  eq(child.lua_get("#vim.api.nvim_list_tabpages()"), tabs)
end

T["switch()"]["create"] = new_set()

T["switch()"]["create"]["creates the only candidate without asking"] = function()
  child.lua("stub_select(1)")
  touch("pkg/user.go")
  edit("pkg/user.go")
  switch()

  eq(current(), "pkg/user_test.go")
  eq(child.lua_get("select_items"), vim.NIL) -- 選択 UI は出ない
  eq(exists("pkg/user_test.go"), false) -- バッファを開くだけで、ファイルはまだ書き込まない
  eq(last_notification().msg:match("^新規作成（未保存）") ~= nil, true)
end

T["switch()"]["create"]["asks which file to create when there are several candidates"] = function()
  child.lua("stub_select(3)")
  touch("src/api.ts")
  edit("src/api.ts")
  switch()

  eq(child.lua_get("select_items"), { "src/api.test.ts", "src/api.spec.ts", "src/__tests__/api.test.ts" })
  eq(child.lua_get("select_prompt"), "作成するファイルを選択")
  eq(current(), "src/__tests__/api.test.ts")
  eq(exists("src/__tests__"), true) -- 保存できるよう親ディレクトリは作成される
end

T["switch()"]["create"]["does nothing when selection is cancelled"] = function()
  child.lua("stub_select(0)")
  touch("src/api.ts")
  edit("src/api.ts")
  switch()

  eq(current(), "src/api.ts")
  eq(child.lua_get("#notifications"), 0)
end

T["switch()"]["create"]["warns instead of creating when create = false"] = function()
  child.lua([[require("test-switch").setup({ create = false })]])
  touch("pkg/user.go")
  edit("pkg/user.go")
  switch()

  eq(current(), "pkg/user.go")
  eq(last_notification(), { msg = "切り替え先が見つかりません", level = WARN })
end

T["switch()"]["warns when no rule matches"] = function()
  touch("README.md")
  edit("README.md")
  switch()

  eq(current(), "README.md")
  eq(last_notification(), { msg = "マッチするルールがありません: README.md", level = WARN })
end

T["switch()"]["warns on unnamed buffer"] = function()
  switch()
  eq(last_notification(), { msg = "バッファにファイル名がありません", level = WARN })
end

T["switch()"]["rejects unknown open command"] = function()
  touch("pkg/user.go", "pkg/user_test.go")
  edit("pkg/user.go")
  switch("badcmd")

  eq(current(), "pkg/user.go")
  eq(last_notification(), { msg = "不明な開き方です: badcmd", level = ERROR })
end

T["setup()"] = new_set()

T["setup()"]["keeps defaults when called without options"] = function()
  child.lua([[require("test-switch").setup()]])
  eq(
    child.lua_get([[vim.deep_equal(require("test-switch").options, require("test-switch.config").defaults)]]),
    true
  )
end

T["setup()"]["extra_rules take priority over default rules"] = function()
  child.lua([[
    require("test-switch").setup({
      extra_rules = { { from = "^(.+)%.go$", to = { "%1_custom_test.go" } } },
    })
  ]])
  eq(child.lua_get([[require("test-switch").options.rules[1].to]]), { "%1_custom_test.go" })
  eq(
    child.lua_get([[#require("test-switch").options.rules]]),
    child.lua_get([[#require("test-switch.config").defaults.rules]]) + 1
  )

  touch("pkg/user.go", "pkg/user_custom_test.go", "pkg/user_test.go")
  edit("pkg/user.go")
  switch()
  eq(current(), "pkg/user_custom_test.go")
end

T["setup()"]["rules replace default rules entirely"] = function()
  child.lua([[
    require("test-switch").setup({
      rules = { { from = "^(.+)%.py$", to = { "%1_test.py" } } },
    })
  ]])
  eq(child.lua_get([[#require("test-switch").options.rules]]), 1)

  touch("pkg/user.go", "pkg/user_test.go")
  edit("pkg/user.go")
  switch()
  eq(current(), "pkg/user.go") -- Go のルールは消えている
end

T["setup()"]["does not mutate defaults"] = function()
  child.lua([[
    local before = #require("test-switch.config").defaults.rules
    require("test-switch").setup({ extra_rules = { { from = "x", to = { "y" } } } })
    require("test-switch").setup({ extra_rules = { { from = "x", to = { "y" } } } })
    _G.before, _G.after = before, #require("test-switch.config").defaults.rules
  ]])
  eq(child.lua_get("after"), child.lua_get("before"))
end

T["setup()"]["does not mutate user options"] = function()
  -- lazy.nvim は :Lazy reload で同じ opts テーブルを再利用するので、書き換えると壊れる
  child.lua([[
    _G.opts = { extra_rules = { { from = "x", to = { "y" } } } }
    require("test-switch").setup(opts)
    require("test-switch").setup(opts)
  ]])
  eq(child.lua_get("#opts.extra_rules"), 1)
  eq(
    child.lua_get([[#require("test-switch").options.rules]]),
    child.lua_get([[#require("test-switch.config").defaults.rules]]) + 1
  )
end

T[":TestSwitch"] = new_set()

T[":TestSwitch"]["completes open commands"] = function()
  eq(child.fn.getcompletion("TestSwitch ", "cmdline"), { "edit", "split", "vsplit", "tabedit" })
end

return T
