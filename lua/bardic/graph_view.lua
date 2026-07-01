local cli = require("bardic.cli")
local config = require("bardic.config")
local graph = require("bardic.graph")

local M = {}

M.state = nil

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-bardic" })
end

local function dot_escape(value)
  return tostring(value or ""):gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
end

local function edge_color(edge)
  if edge.is_jump then
    return "#d4af37", "bold"
  end
  if edge.is_conditional then
    return "#ff9f43", "dashed"
  end
  return "#9b4dca", "solid"
end

function M.to_dot(model)
  local lines = {
    "digraph BardicStory {",
    "  graph [rankdir=TB, bgcolor=\"#1a0033\", pad=0.3, nodesep=0.8, ranksep=1.0];",
    "  node [shape=box, style=\"rounded,filled\", fontname=\"Georgia\", fontsize=14, color=\"#9b4dca\", fontcolor=\"#f4e4c1\", fillcolor=\"#2d1b4e\"];",
    "  edge [fontname=\"Helvetica\", fontsize=10, fontcolor=\"#f4e4c1\", arrowsize=0.8];",
  }

  for _, node in ipairs(model.nodes or {}) do
    local fill = "#2d1b4e"
    local color = "#9b4dca"
    local penwidth = "2"
    if node.is_missing then
      fill = "#4a0000"
      color = "#ff4444"
      penwidth = "3"
    elseif node.is_orphan then
      fill = "#1a3a4a"
    end
    if node.is_start then
      color = "#d4af37"
      penwidth = "3"
    elseif node.has_params then
      color = "#66bb6a"
      penwidth = "3"
    end
    table.insert(
      lines,
      string.format(
        '  "%s" [label="%s", tooltip="%s", fillcolor="%s", color="%s", penwidth=%s];',
        dot_escape(node.id),
        dot_escape(node.label),
        dot_escape(node.title),
        fill,
        color,
        penwidth
      )
    )
  end

  for _, edge in ipairs(model.edges or {}) do
    local color, style = edge_color(edge)
    table.insert(
      lines,
      string.format(
        '  "%s" -> "%s" [label="%s", tooltip="%s", color="%s", fontcolor="%s", style="%s", penwidth=%d];',
        dot_escape(edge.from),
        dot_escape(edge.to),
        dot_escape(edge.label),
        dot_escape(edge.title),
        color,
        color,
        style,
        edge.is_jump and 3 or 2
      )
    )
  end

  table.insert(lines, "}")
  return table.concat(lines, "\n")
end

function M.render_dot(model, output, format)
  format = format or config.get().graph.format or "png"
  output = output or (vim.fn.tempname() .. "." .. format)
  if vim.fn.executable("dot") ~= 1 then
    return nil, "Graphviz 'dot' executable not found"
  end
  local dot_file = vim.fn.tempname() .. ".dot"
  vim.fn.writefile(vim.split(M.to_dot(model), "\n", { plain = true }), dot_file)
  local result = cli.run({ "dot", "-T" .. format, dot_file, "-o", output })
  if result.code ~= 0 then
    return nil, result.stderr ~= "" and result.stderr or result.stdout
  end
  return output, nil
end

function M.build_model(file)
  local opts = config.get()
  if opts.prefer_cli and cli.executable_exists(opts.bardic_cmd) then
    local compiled = cli.compile_file(file)
    if compiled and compiled.story then
      local ok, model = pcall(graph.from_story, compiled.story)
      if ok then
        model.source = "bardic-cli"
        return model, nil
      end
    end
  end
  local model, err = graph.from_file(file)
  if model then
    model.source = "simple-parser"
  end
  return model, err
end

local function show_text_fallback(buf, model, image_path, reason)
  local lines = {
    "Bardic Story Graph",
    "",
    reason and ("Image display unavailable: " .. reason) or "Image display unavailable.",
    image_path and ("Rendered graph: " .. image_path) or "No rendered image was produced.",
    "",
    string.format("Source: %s", model.source or "unknown"),
    string.format("Passages: %d", #(model.order or {})),
    string.format("Choices: %d", #(model.edges or {})),
    string.format("Missing: %d", #(model.missing_passages or {})),
    string.format("Orphans: %d", #(model.orphan_passages or {})),
    "",
    "Install/configure image.nvim and use a graphics-capable terminal for inline images.",
  }
  vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
end

local function render_image(buf, win, path, model)
  local graph_opts = config.get().graph
  if graph_opts.open_command then
    vim.fn.jobstart({ graph_opts.open_command, path }, { detach = true })
    show_text_fallback(buf, model, path, "opened graph with external command")
    return true
  end

  if graph_opts.use_image_nvim then
    local ok, image_mod = pcall(require, "image")
    if ok and image_mod and image_mod.from_file then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
      local image = image_mod.from_file(path, { buffer = buf, window = win, with_virtual_padding = true })
      if image then
        image:render()
        return true
      end
    end
  end

  show_text_fallback(buf, model, path, "image.nvim is not available")
  return false
end

function M.show(file)
  file = file or cli.current_file()
  if type(file) == "table" then
    file = nil
  end
  if not file then
    local err
    file, err = cli.current_file()
    if not file then
      notify(err, vim.log.levels.ERROR)
      return nil
    end
  end

  local model, err = M.build_model(file)
  if not model then
    notify(err or "Could not build Bardic graph", vim.log.levels.ERROR)
    return nil
  end

  local image_path, render_err = M.render_dot(model, nil, config.get().graph.format)

  vim.cmd(config.get().graph.split)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_name(buf, "Bardic Story Graph")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "bardicgraph"
  vim.wo[win].wrap = false

  if image_path then
    render_image(buf, win, image_path, model)
  else
    show_text_fallback(buf, model, nil, render_err)
  end

  vim.keymap.set("n", "r", function()
    M.refresh()
  end, { buffer = buf, nowait = true, desc = "Refresh Bardic graph" })
  vim.keymap.set("n", "e", function()
    M.export()
  end, { buffer = buf, nowait = true, desc = "Export Bardic graph" })

  M.state = { file = file, model = model, image_path = image_path, buf = buf, win = win }
  require("bardic.graph_index").open(model, file)
  return M.state
end

function M.refresh()
  if not M.state or not M.state.file then
    return M.show()
  end
  return M.show(M.state.file)
end

function M.export(path)
  if not M.state or not M.state.model then
    notify("No Bardic graph is currently open", vim.log.levels.WARN)
    return nil
  end
  local format = config.get().graph.format or "png"
  path = path or vim.fn.input("Export graph path: ", vim.fn.getcwd() .. "/story-graph." .. format, "file")
  if path == "" then
    return nil
  end
  local output, err = M.render_dot(M.state.model, path, format)
  if not output then
    notify(err, vim.log.levels.ERROR)
    return nil
  end
  notify("Exported Bardic graph to " .. output)
  return output
end

return M
