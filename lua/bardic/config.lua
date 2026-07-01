local M = {}

M.defaults = {
  bardic_cmd = "bardic",
  python_cmd = nil,
  timeout_ms = 10000,
  prefer_cli = true,
  auto_refresh_graph = true,
  graph = {
    image_backend = "auto",
    open_command = nil,
  },
}

M.options = vim.deepcopy(M.defaults)

---@param opts table|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M
