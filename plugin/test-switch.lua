-- plugin/ 配下は起動時に自動で読み込まれる。
-- 起動を遅くしないよう、ここではコマンドの定義だけを行い、
-- 本体は実行時に require して読み込む。
if vim.g.loaded_test_switch then
  return
end
vim.g.loaded_test_switch = true

vim.api.nvim_create_user_command("TestSwitch", function(args)
  require("test-switch").switch(args.args ~= "" and args.args or nil)
end, {
  nargs = "?",
  complete = function()
    return { "edit", "split", "vsplit", "tabedit" }
  end,
  desc = "テストファイルと実装ファイルを切り替える",
})
