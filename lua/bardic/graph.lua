local parser = require("bardic.parser")

local M = {}

local function normalize_text(value, fallback)
  fallback = fallback or "→"
  if value == nil then
    return fallback
  end
  if type(value) == "string" then
    return value
  end
  if type(value) == "table" then
    local parts = {}
    for _, token in ipairs(value) do
      if type(token) == "string" then
        table.insert(parts, token)
      elseif type(token) == "table" then
        table.insert(parts, token.value or token.text or "")
      end
    end
    local text = table.concat(parts, "")
    if text ~= "" then
      return text
    end
  end
  return fallback
end

local function wrap_words(label, max_length)
  label = tostring(label or "")
  if #label <= max_length then
    return label
  end
  local lines = {}
  local current = ""
  for word in label:gmatch("%S+") do
    if #current > 0 and #current + #word + 1 > max_length then
      table.insert(lines, current)
      current = word
    else
      current = current == "" and word or (current .. " " .. word)
    end
  end
  if current ~= "" then
    table.insert(lines, current)
  end
  if #lines == 0 then
    for index = 1, #label, max_length do
      table.insert(lines, label:sub(index, index + max_length - 1))
    end
  end
  return table.concat(lines, "\n")
end

local function collect_nested_choices(content, out)
  if type(content) ~= "table" then
    return
  end
  for _, token in ipairs(content) do
    if type(token) == "table" then
      if token.type == "jump" and token.target then
        table.insert(out, {
          text = "→",
          target = token.target,
          is_jump = true,
          type = "jump",
        })
      end
      if token.type == "for_loop" then
        for _, choice in ipairs(token.choices or {}) do
          table.insert(out, choice)
        end
        collect_nested_choices(token.content, out)
      elseif token.type == "conditional" then
        for _, branch in ipairs(token.branches or {}) do
          for _, choice in ipairs(branch.choices or {}) do
            table.insert(out, choice)
          end
          collect_nested_choices(branch.content, out)
        end
      elseif token.content then
        collect_nested_choices(token.content, out)
      end
    end
  end
end

local function build(passages, order, start_passage)
  local nodes = {}
  local edges = {}
  local referenced = {}
  local all_targets = {}
  local seen_edges = {}

  for _, passage_name in ipairs(order) do
    local passage = passages[passage_name]
    local choices = vim.list_extend(vim.deepcopy(passage.choices or {}), {})
    collect_nested_choices(passage.content, choices)

    for _, choice in ipairs(choices) do
      local target = choice.target
      if target and target ~= "" then
        all_targets[target] = true
        if passages[target] then
          referenced[target] = true
        end
        local key = passage_name .. "\0" .. target .. "\0" .. normalize_text(choice.text)
        if not seen_edges[key] then
          seen_edges[key] = true
          local text = normalize_text(choice.text)
          table.insert(edges, {
            from = passage_name,
            to = target,
            label = wrap_words(text, 18),
            title = text,
            is_conditional = choice.is_conditional or choice.condition ~= nil,
            is_jump = choice.is_jump or choice.type == "jump" or choice.text == nil,
            line = choice.line,
          })
        end
      end
    end
  end

  local missing = {}
  for target in pairs(all_targets) do
    if not passages[target] then
      table.insert(missing, target)
    end
  end
  table.sort(missing)

  local orphan = {}
  for _, passage_name in ipairs(order) do
    if passage_name ~= start_passage and not referenced[passage_name] then
      table.insert(orphan, passage_name)
    end
  end

  local missing_lookup = {}
  for _, name in ipairs(missing) do
    missing_lookup[name] = true
  end
  local orphan_lookup = {}
  for _, name in ipairs(orphan) do
    orphan_lookup[name] = true
  end

  for _, passage_name in ipairs(order) do
    local passage = passages[passage_name]
    local has_params = passage.params and #passage.params > 0
    table.insert(nodes, {
      id = passage_name,
      label = wrap_words(passage.full_name or passage.name or passage_name, 20),
      title = passage_name,
      line = passage.line,
      is_start = passage_name == start_passage,
      has_params = has_params,
      is_missing = false,
      is_orphan = orphan_lookup[passage_name] or false,
    })
  end

  for _, name in ipairs(missing) do
    table.insert(nodes, {
      id = name,
      label = wrap_words(name, 20) .. "\nMISSING",
      title = "Missing passage: " .. name,
      is_start = false,
      has_params = false,
      is_missing = true,
      is_orphan = false,
    })
  end

  return {
    nodes = nodes,
    edges = edges,
    passages = passages,
    order = order,
    start_passage = start_passage,
    missing_passages = missing,
    orphan_passages = orphan,
    missing_lookup = missing_lookup,
    orphan_lookup = orphan_lookup,
  }
end

function M.from_parsed(parsed)
  return build(parsed.passages or {}, parsed.order or vim.tbl_keys(parsed.passages or {}), parsed.start_passage)
end

function M.from_source(content)
  return M.from_parsed(parser.parse(content))
end

function M.from_file(path)
  local parsed, err = parser.parse_file(path)
  if not parsed then
    return nil, err
  end
  return M.from_parsed(parsed), nil
end

function M.from_story(story)
  local passages = {}
  local order = {}
  for name, passage in pairs(story.passages or {}) do
    local params = {}
    for _, param in ipairs(passage.params or {}) do
      table.insert(params, type(param) == "table" and (param.name or tostring(param[1])) or tostring(param))
    end
    passages[name] = vim.tbl_deep_extend("force", vim.deepcopy(passage), {
      id = name,
      name = passage.name or name,
      full_name = passage.name or name,
      params = params,
      line = passage.line,
    })
    table.insert(order, name)
  end
  table.sort(order)
  local start = story.start_passage or story.initial_passage or story.startPassage or order[1]
  return build(passages, order, start)
end

return M
