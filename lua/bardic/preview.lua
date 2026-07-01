local cli = require("bardic.cli")
local config = require("bardic.config")
local parser = require("bardic.parser")

local M = {}

M.state = nil

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-bardic" })
end

local function plugin_root()
  local source = debug.getinfo(1, "S").source:gsub("^@", "")
  return vim.fn.fnamemodify(source, ":h:h:h")
end

local function server_path()
  return plugin_root() .. "/python/preview_server.py"
end

local function append_lines(data)
  local lines = {}
  for _, item in ipairs(data or {}) do
    if item and item ~= "" then
      table.insert(lines, item)
    end
  end
  return lines
end

local function send(command)
  if not M.state or not M.state.job then
    notify("Bardic preview is not running", vim.log.levels.ERROR)
    return
  end
  vim.fn.chansend(M.state.job, vim.json.encode(command) .. "\n")
end

local function render(payload)
  if not M.state or not M.state.buf then
    return
  end
  local lines = {}
  local choice_lines = {}
  table.insert(lines, "# " .. (payload.passage_id or "Bardic Preview"))
  table.insert(lines, "")
  for _, line in ipairs(vim.split(payload.content or "", "\n", { plain = true })) do
    table.insert(lines, line)
  end
  table.insert(lines, "")
  if payload.choices and #payload.choices > 0 then
    table.insert(lines, "Choices:")
    for index, choice in ipairs(payload.choices) do
      local text = type(choice) == "table" and (choice.text or choice.label or vim.inspect(choice)) or tostring(choice)
      table.insert(lines, string.format("  %d. %s", index, text))
      choice_lines[#lines] = index - 1
    end
  else
    table.insert(lines, "◆ The End ◆")
  end
  table.insert(lines, "")
  table.insert(lines, "Mappings: <CR> choose  r reset  e edit state  q close")

  vim.api.nvim_set_option_value("modifiable", true, { buf = M.state.buf })
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.state.buf })
  M.state.choice_lines = choice_lines
end

local function render_error(payload)
  if not M.state or not M.state.buf then
    notify(payload.message or payload.error or "Bardic preview error", vim.log.levels.ERROR)
    return
  end
  local lines = {
    "Bardic Preview Error",
    "",
    payload.message or payload.error or "Unknown error",
  }
  if payload.traceback then
    table.insert(lines, "")
    vim.list_extend(lines, vim.split(payload.traceback, "\n", { plain = true }))
  end
  vim.api.nvim_set_option_value("modifiable", true, { buf = M.state.buf })
  vim.api.nvim_buf_set_lines(M.state.buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = M.state.buf })
end

local function handle_payload(payload)
  if payload.status == "ready" then
    send({ type = "preview", passage = M.state.passage, state = M.state.user_state or {} })
  elseif payload.error then
    render_error(payload)
  elseif payload.content ~= nil then
    render(payload)
  end
end

local function start_server(story, passage, state)
  local py = config.get().python_cmd or vim.fn.exepath("python3") or "python3"
  local script = server_path()
  if vim.fn.filereadable(script) ~= 1 then
    notify("Preview server not found: " .. script, vim.log.levels.ERROR)
    return nil
  end

  vim.cmd(config.get().preview.split)
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_buf_set_name(buf, "Bardic Preview")
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "markdown"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "Starting Bardic preview..." })
  vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

  M.state = {
    buf = buf,
    win = win,
    passage = passage,
    user_state = state or {},
    choice_lines = {},
    stdout = "",
  }

  local job = vim.fn.jobstart({ py, script }, {
    stdin = "pipe",
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      for _, line in ipairs(append_lines(data)) do
        local ok, payload = pcall(vim.json.decode, line)
        if ok then
          handle_payload(payload)
        end
      end
    end,
    on_stderr = function(_, data)
      local text = table.concat(append_lines(data), "\n")
      if text ~= "" then
        render_error({ message = text })
      end
    end,
    on_exit = function(_, code)
      if code ~= 0 and M.state and M.state.buf and vim.api.nvim_buf_is_valid(M.state.buf) then
        -- If an error was already rendered, leave it visible.
      end
    end,
  })

  if job <= 0 then
    notify("Could not start Bardic preview server", vim.log.levels.ERROR)
    return nil
  end

  M.state.job = job
  vim.fn.chansend(job, vim.json.encode(story) .. "\n")

  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    local index = M.state.choice_lines[line]
    if index ~= nil then
      send({ type = "choice", index = index })
    end
  end, { buffer = buf, desc = "Choose Bardic preview choice" })
  vim.keymap.set("n", "r", function()
    send({ type = "reset" })
  end, { buffer = buf, desc = "Reset Bardic preview" })
  vim.keymap.set("n", "e", function()
    local value = vim.fn.input("State JSON: ", vim.json.encode(M.state.user_state or {}))
    if value == "" then
      return
    end
    local ok, decoded = pcall(vim.json.decode, value)
    if not ok then
      notify("Invalid state JSON: " .. tostring(decoded), vim.log.levels.ERROR)
      return
    end
    M.state.user_state = decoded
    send({ type = "preview", passage = M.state.passage, state = decoded })
  end, { buffer = buf, desc = "Edit Bardic preview state" })
  vim.keymap.set("n", "q", function()
    pcall(send, { type = "exit" })
    vim.cmd.close()
  end, { buffer = buf, desc = "Close Bardic preview" })

  return M.state
end

function M.passage(passage, state)
  local file, err = cli.current_file()
  if not file then
    notify(err, vim.log.levels.ERROR)
    return nil
  end
  passage = passage or (parser.find_passage_at_cursor(0) or {}).name
  if not passage then
    notify("Cursor is not inside a Bardic passage", vim.log.levels.ERROR)
    return nil
  end

  local compiled, compile_err = cli.compile_file(file)
  if not compiled then
    cli.message_error(compile_err)
    return nil
  end
  local story = compiled.story
  story.initial_passage = story.initial_passage or story.start_passage or story.startPassage
  return start_server(story, passage, state or config.get().preview.state)
end

return M
