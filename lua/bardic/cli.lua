local config = require("bardic.config")

local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-bardic" })
end

function M.executable_exists(cmd)
  return cmd and cmd ~= "" and vim.fn.executable(cmd) == 1
end

local function with_timeout_ms()
  return config.get().timeout_ms or 10000
end

---@param argv string[]
---@param opts table|nil
---@return table
function M.run(argv, opts)
  opts = opts or {}
  if not argv[1] or not M.executable_exists(argv[1]) then
    return {
      code = 127,
      stdout = "",
      stderr = string.format("Executable not found: %s", argv[1] or "nil"),
    }
  end

  if vim.system then
    local handle = vim.system(argv, {
      text = true,
      cwd = opts.cwd,
      stdin = opts.stdin,
    })
    local completed = handle:wait(opts.timeout_ms or with_timeout_ms())
    return {
      code = completed.code,
      stdout = completed.stdout or "",
      stderr = completed.stderr or "",
    }
  end

  local command = table.concat(vim.tbl_map(vim.fn.shellescape, argv), " ")
  local output = vim.fn.system(command)
  return {
    code = vim.v.shell_error,
    stdout = output,
    stderr = vim.v.shell_error == 0 and "" or output,
  }
end

local function bardic_cmd()
  return config.get().bardic_cmd or "bardic"
end

local function tmpname(suffix)
  return vim.fn.tempname() .. suffix
end

function M.current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    return nil, "Current buffer has no file name"
  end
  if vim.bo.modified then
    vim.cmd.write()
  end
  return file, nil
end

function M.parse_error(stderr, file)
  local line_file, line_number, message = stderr:match("Error in ([^:]+):(%d+):%s*(.+)")
  if line_number then
    return {
      filename = line_file ~= "" and line_file or file,
      lnum = tonumber(line_number),
      col = 1,
      text = message,
      type = "E",
    }
  end

  line_number, message = stderr:match("line%s+(%d+)[:%s]+(.+)")
  if line_number then
    return {
      filename = file,
      lnum = tonumber(line_number),
      col = 1,
      text = message,
      type = "E",
    }
  end

  return {
    filename = file,
    lnum = 1,
    col = 1,
    text = stderr:gsub("^%s+", ""):gsub("%s+$", ""),
    type = "E",
  }
end

function M.set_quickfix(items, title)
  if not config.get().quickfix then
    return
  end
  vim.fn.setqflist({}, " ", { title = title or "Bardic", items = items })
  if #items > 0 then
    vim.cmd.copen()
  else
    vim.cmd.cclose()
  end
end

function M.compile_file(file, opts)
  opts = opts or {}
  if not M.executable_exists(bardic_cmd()) then
    return nil, {
      type = "bardic-not-found",
      message = "Bardic CLI not found. Install with: pip install bardic",
      stderr = "",
    }
  end

  local output = opts.output or tmpname(".json")
  local result = M.run({ bardic_cmd(), "compile", file, "-o", output }, opts)
  if result.code ~= 0 then
    local stderr = result.stderr ~= "" and result.stderr or result.stdout
    M.set_quickfix({ M.parse_error(stderr, file) }, "Bardic compile")
    return nil, {
      type = "compile-error",
      message = stderr,
      stderr = stderr,
      output = output,
    }
  end

  local json = table.concat(vim.fn.readfile(output), "\n")
  local ok, story = pcall(vim.json.decode, json)
  if not ok then
    return nil, {
      type = "json-error",
      message = "Could not parse compiled Bardic JSON: " .. tostring(story),
      output = output,
    }
  end

  M.set_quickfix({}, "Bardic compile")
  return { story = story, output = output, stdout = result.stdout }, nil
end

function M.compile_current(opts)
  local file, err = M.current_file()
  if not file then
    return nil, { message = err }
  end
  return M.compile_file(file, opts)
end

function M.lint_file(file, opts)
  opts = opts or {}
  if not M.executable_exists(bardic_cmd()) then
    return nil, {
      type = "bardic-not-found",
      message = "Bardic CLI not found. Install with: pip install bardic",
    }
  end

  local result = M.run({ bardic_cmd(), "lint", file }, opts)
  local output = (result.stdout or "") .. (result.stderr or "")
  local items = {}
  for line in output:gmatch("[^\n]+") do
    local lnum, message = line:match(":(%d+):%s*(.+)")
    table.insert(items, {
      filename = file,
      lnum = tonumber(lnum) or 1,
      col = 1,
      text = message or line,
      type = result.code == 0 and "I" or "W",
    })
  end
  M.set_quickfix(items, "Bardic lint")
  return { code = result.code, output = output, items = items }, nil
end

function M.lint_current(opts)
  local file, err = M.current_file()
  if not file then
    return nil, { message = err }
  end
  return M.lint_file(file, opts)
end

function M.graph_file(file, output, format)
  format = format or config.get().graph.format or "png"
  output = output or tmpname("-story-graph")
  local compiled, compile_err = M.compile_file(file)
  if not compiled then
    return nil, compile_err
  end

  local result = M.run({ bardic_cmd(), "graph", compiled.output, "-o", output, "-f", format })
  if result.code ~= 0 then
    return nil, {
      type = "graph-error",
      message = result.stderr ~= "" and result.stderr or result.stdout,
    }
  end
  return output .. "." .. format, nil
end

function M.message_error(err)
  notify(err and err.message or "Unknown Bardic error", vim.log.levels.ERROR)
end

return M
