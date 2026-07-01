require("bardic").setup()

local commands = vim.api.nvim_get_commands({})
assert(commands.BardicCompile ~= nil, "BardicCompile command should exist")
assert(commands.BardicGraph ~= nil, "BardicGraph command should exist")

vim.cmd("setfiletype bardic")
assert(vim.bo.filetype == "bardic", "bardic filetype should be settable")

local parser = require("bardic.parser")
local graph = require("bardic.graph")

local source = [[
@start Start

:: Start
Welcome.
+ [Go north] -> North
+ {has_key} [Unlock door] -> Vault
-> Missing

@py:
+ [Ignored] -> Nope
@endpy

:: North(item)
+ [Back] -> Start

:: Vault
The end.

:: Orphan
No one points here.
]]

local parsed = parser.parse(source)
assert(parsed.start_passage == "Start", "start passage should be parsed")
assert(parsed.passages.Start ~= nil, "Start passage should exist")
assert(#parsed.passages.Start.choices == 3, "Start should have three choices/jumps")
assert(parsed.passages.North.full_name == "North(item)", "parameterized passage full name should be kept")
assert(#parsed.passages.North.params == 1, "parameterized passage should expose params")
assert(parsed.passages.Nope == nil, "Python block choices should be ignored by simple parser")

local model = graph.from_parsed(parsed)
assert(#model.edges == 4, "graph should include all simple edges")
assert(model.missing_lookup.Missing == true, "missing passage should be marked")
assert(model.orphan_lookup.Orphan == true, "orphan passage should be marked")
