local config = require("test-switch.config")
local resolver = require("test-switch.resolver")

local M = {}

---@type TestSwitch.Config
M.options = vim.deepcopy(config.defaults)

local open_cmds = { edit = true, split = true, vsplit = true, tabedit = true }

---@param msg string
---@param level? integer
local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "test-switch" })
end

---@param path string
---@param cmd string
local function open(path, cmd)
  vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
end

---@param path string
---@param cmd string
local function create(path, cmd)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  open(path, cmd)
  notify("新規作成（未保存）: " .. vim.fn.fnamemodify(path, ":~:."))
end

---@param opts? TestSwitch.Config
function M.setup(opts)
  opts = opts or {}
  -- vim.tbl_deep_extend はリストをインデックス単位でマージしてしまうため、
  -- rules は浅いマージにして、ユーザー指定があれば丸ごと置き換える
  local options = vim.tbl_extend("force", vim.deepcopy(config.defaults), opts)
  options.rules = vim.list_extend(vim.deepcopy(opts.extra_rules or {}), options.rules)
  M.options = options
end

--- 現在のバッファのテスト/実装ファイルに切り替える
---@param cmd? "edit"|"split"|"vsplit"|"tabedit"
function M.switch(cmd)
  cmd = cmd or "edit"
  if not open_cmds[cmd] then
    notify("不明な開き方です: " .. cmd, vim.log.levels.ERROR)
    return
  end

  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    notify("バッファにファイル名がありません", vim.log.levels.WARN)
    return
  end

  local candidates = resolver.candidates(vim.fs.normalize(path), M.options.rules)
  if #candidates == 0 then
    notify("マッチするルールがありません: " .. vim.fn.fnamemodify(path, ":t"), vim.log.levels.WARN)
    return
  end

  for _, candidate in ipairs(candidates) do
    if vim.uv.fs_stat(candidate) then
      open(candidate, cmd)
      return
    end
  end

  if not M.options.create then
    notify("切り替え先が見つかりません", vim.log.levels.WARN)
    return
  end

  if #candidates == 1 then
    create(candidates[1], cmd)
    return
  end

  -- vim.ui.select は LazyVim だと snacks.nvim の picker で表示される
  vim.ui.select(candidates, {
    prompt = "作成するファイルを選択",
    format_item = function(item)
      return vim.fn.fnamemodify(item, ":~:.")
    end,
  }, function(choice)
    if choice then
      create(choice, cmd)
    end
  end)
end

return M
