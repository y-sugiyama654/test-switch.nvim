-- テスト用の最小構成。ユーザー設定を読まずに、このプラグインと mini.test だけを読み込む。
-- テストを実行する親プロセスと、テスト内で起動する子プロセスの両方がこのファイルを使う。
vim.opt.rtp:append(vim.fn.getcwd())

if #vim.api.nvim_list_uis() == 0 then
  vim.opt.rtp:append(vim.fn.getcwd() .. "/deps/mini.test")
  require("mini.test").setup()
end
