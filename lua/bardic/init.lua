local M = {}

---Configure nvim-bardic.
---@param opts table|nil
function M.setup(opts)
  require("bardic.config").setup(opts or {})
  require("bardic.commands").setup()
end

return M
