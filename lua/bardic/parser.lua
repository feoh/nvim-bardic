local M = {}

local function trim(value)
  return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function split_params(params)
  if not params or params == "" then
    return {}
  end
  local result = {}
  for param in params:gmatch("([^,]+)") do
    local name = trim(param):match("^([^=]+)")
    if name then
      table.insert(result, trim(name))
    end
  end
  return result
end

local function add_choice(passage, choice)
  passage.choices = passage.choices or {}
  table.insert(passage.choices, choice)
end

---@param content string
---@return table
function M.parse(content)
  local passages = {}
  local order = {}
  local current = nil
  local in_py_block = false
  local explicit_start = nil

  local lines = vim.split(content, "\n", { plain = true })
  for index, raw_line in ipairs(lines) do
    local line = trim(raw_line)

    if line:match("^@start%s+") then
      explicit_start = line:match("^@start%s+([%w_.]+)") or explicit_start
    end

    if line == "@py" or line == "@py:" or line:match("^<<%s*py%s*>>") then
      in_py_block = true
    elseif line:match("^@endpy") or (in_py_block and line:match("^>>$")) then
      in_py_block = false
    end

    if not in_py_block then
      local header = line:match("^::%s+(.+)$")
      local name = header and header:match("^([%w_.]+)") or nil
      local rest = name and header:sub(#name + 1) or ""
      local params = rest:match("^%s*(%b())")
      local tag = rest:match("%s+(%^%w+)")
      if name then
        local params_content = params and params:sub(2, -2) or ""
        current = {
          id = name,
          name = name,
          full_name = name .. (params or ""),
          params = split_params(params_content),
          tags = tag and { tag:gsub("^%^", "") } or {},
          line = index,
          choices = {},
        }
        passages[name] = current
        table.insert(order, name)
      elseif current then
        local jump_target = line:match("^%-%>%s*([%w_.]+)")
        if jump_target then
          add_choice(current, {
            text = "→",
            target = jump_target,
            type = "jump",
            is_jump = true,
            line = index,
          })
        else
          local condition, text, target = line:match("^[+*]%s+%{([^}]+)%}%s+%[(.-)%]%s+%-%>%s*([%w_.]+)")
          if target then
            add_choice(current, {
              text = text,
              target = target,
              condition = condition,
              is_conditional = true,
              line = index,
            })
          else
            text, target = line:match("^[+*]%s+%[(.-)%]%s+%-%>%s*([%w_.]+)")
            if target then
              add_choice(current, {
                text = text,
                target = target,
                is_conditional = false,
                line = index,
              })
            elseif line:find("%-%>") then
              target = line:match("%-%>%s*([%w_.]+)")
              text = line:match("%[(.-)%]")
              if target then
                add_choice(current, {
                  text = text or "→",
                  target = target,
                  is_conditional = text ~= nil,
                  is_jump = text == nil,
                  line = index,
                })
              end
            end
          end
        end
      end
    end
  end

  return {
    passages = passages,
    order = order,
    start_passage = explicit_start or order[1],
    source = "simple-parser",
  }
end

---@param path string
---@return table|nil, string|nil
function M.parse_file(path)
  local lines = vim.fn.readfile(path)
  if vim.v.shell_error ~= 0 then
    return nil, "Could not read " .. path
  end
  return M.parse(table.concat(lines, "\n")), nil
end

function M.find_passage_at_cursor(bufnr, lnum)
  bufnr = bufnr or 0
  lnum = lnum or vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local current = nil
  for index, line in ipairs(lines) do
    local name = trim(line):match("^::%s+([%w_.]+)")
    if name then
      current = { name = name, line = index }
    end
    if index == lnum then
      return current
    end
  end
  return current
end

return M
