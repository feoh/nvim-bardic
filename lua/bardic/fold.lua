local M = {}

function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  if line:match("^%s*::") then
    return ">1"
  end
  local next_line = vim.fn.getline(lnum + 1)
  if next_line == "" and lnum == vim.fn.line("$") then
    return "0"
  end
  return "1"
end

function M.foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local count = vim.v.foldend - vim.v.foldstart + 1
  return string.format("%s  [%d lines]", line:gsub("^%s+", ""), count)
end

return M
