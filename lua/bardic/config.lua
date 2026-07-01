local M = {}

M.defaults = {
  bardic_cmd = "bardic",
  python_cmd = nil,
  timeout_ms = 10000,
  prefer_cli = true,
  auto_refresh_graph = true,
  quickfix = true,
  graph = {
    format = "png",
    image_backend = "auto",
    split = "vsplit",
    index_split = "split",
    index_width = 34,
    use_image_nvim = true,
    open_command = nil,
  },
  preview = {
    split = "vsplit",
    state = {},
  },
}

M.options = vim.deepcopy(M.defaults)

---@param opts table|nil
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  if M.options.timeout_ms > 60000 then
    M.options.timeout_ms = 60000
  end
  return M.options
end

function M.get()
  return M.options
end

return M
