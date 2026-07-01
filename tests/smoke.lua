require("bardic").setup()

local commands = vim.api.nvim_get_commands({})
assert(commands.BardicCompile ~= nil, "BardicCompile command should exist")
assert(commands.BardicGraph ~= nil, "BardicGraph command should exist")

vim.cmd("setfiletype bardic")
assert(vim.bo.filetype == "bardic", "bardic filetype should be settable")
