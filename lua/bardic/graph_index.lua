local M = {}

M.state = nil

local function node_by_id(model, id)
  for _, node in ipairs(model.nodes or {}) do
    if node.id == id then
      return node
    end
  end
  return nil
end

local function jump_to_source(file, node)
  if not node or node.is_missing then
    vim.notify("Missing passages do not have a source location", vim.log.levels.WARN, { title = "nvim-bardic" })
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(file))
  local line = node.line or 1
  vim.api.nvim_win_set_cursor(0, { line, 0 })
  vim.cmd.normal({ args = { "zz" }, bang = true })
end

function M.open(model, file)
  local lines = {}
  local lookup = {}
  table.insert(lines, "Bardic Story Graph")
  table.insert(lines, string.format("Passages: %d", #(model.order or {})))
  table.insert(lines, string.format("Choices: %d", #(model.edges or {})))
  table.insert(lines, string.format("Missing: %d", #(model.missing_passages or {})))
  table.insert(lines, string.format("Orphans: %d", #(model.orphan_passages or {})))
  table.insert(lines, "")
  table.insert(lines, "Press <CR> to jump, r to refresh, e to export")
  table.insert(lines, "")

  for _, node in ipairs(model.nodes or {}) do
    local marker = "  "
    if node.is_missing then
      marker = "✗ "
    elseif node.is_orphan then
      marker = "? "
    elseif node.is_start then
      marker = "★ "
    elseif node.has_params then
      marker = "↻ "
    end
    local line = marker .. node.id
    table.insert(lines, line)
    lookup[#lines] = node.id
  end

  vim.cmd("botright vsplit")
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_name(buf, "Bardic Graph Index")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "bardicgraph"
  vim.wo[win].wrap = false
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  local ns = vim.api.nvim_create_namespace("bardic_graph_index")
  for lnum, id in pairs(lookup) do
    local node = node_by_id(model, id)
    local group = "Identifier"
    if node.is_missing then
      group = "ErrorMsg"
    elseif node.is_orphan then
      group = "WarningMsg"
    elseif node.is_start then
      group = "Title"
    end
    vim.api.nvim_buf_add_highlight(buf, ns, group, lnum - 1, 0, -1)
  end

  local function jump()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]
    local id = lookup[lnum]
    if id then
      jump_to_source(file, node_by_id(model, id))
    end
  end

  vim.keymap.set("n", "<CR>", jump, { buffer = buf, nowait = true, desc = "Jump to Bardic passage" })
  vim.keymap.set("n", "r", function()
    require("bardic.graph_view").refresh()
  end, { buffer = buf, nowait = true, desc = "Refresh Bardic graph" })
  vim.keymap.set("n", "e", function()
    require("bardic.graph_view").export()
  end, { buffer = buf, nowait = true, desc = "Export Bardic graph" })

  M.state = { buf = buf, win = win, lookup = lookup, file = file, model = model }
  return M.state
end

return M
