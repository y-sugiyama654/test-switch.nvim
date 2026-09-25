-- パスから切り替え先の候補を計算する。
-- Neovim のエディタ状態に依存しない純粋な関数だけを置き、単体テストしやすくしている。
local M = {}

---@param path string 正規化済みの絶対パス
---@param rules TestSwitch.Rule[]
---@return string[] candidates 最初にマッチしたルールの候補。マッチしなければ空
function M.candidates(path, rules)
  for _, rule in ipairs(rules) do
    if path:match(rule.from) then
      return vim.tbl_map(function(to)
        -- gsub は (結果, 置換回数) を返すので、括弧で結果だけを取り出す
        return (path:gsub(rule.from, to))
      end, rule.to)
    end
  end
  return {}
end

return M
