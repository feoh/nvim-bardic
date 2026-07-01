local cli = require("bardic.cli")

local M = {}

local created = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = "nvim-bardic" })
end

local function current_bardic_file()
  local file, err = cli.current_file()
  if not file then
    notify(err, vim.log.levels.ERROR)
    return nil
  end
  return file
end

function M.setup()
  if created then
    return
  end
  created = true

  vim.api.nvim_create_user_command("BardicCompile", function(args)
    local file = args.args ~= "" and args.args or current_bardic_file()
    if not file then
      return
    end
    local result, err = cli.compile_file(file)
    if not result then
      cli.message_error(err)
      return
    end
    notify("Compiled Bardic story to " .. result.output)
  end, { desc = "Compile the current Bardic story", nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("BardicLint", function(args)
    local file = args.args ~= "" and args.args or current_bardic_file()
    if not file then
      return
    end
    local result, err = cli.lint_file(file)
    if not result then
      cli.message_error(err)
      return
    end
    local level = result.code == 0 and vim.log.levels.INFO or vim.log.levels.WARN
    notify(result.code == 0 and "Bardic lint passed" or "Bardic lint reported issues", level)
  end, { desc = "Lint the current Bardic story", nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("BardicGraph", function(args)
    local file = args.args ~= "" and args.args or current_bardic_file()
    if file then
      require("bardic.graph_view").show(file)
    end
  end, { desc = "Show the Bardic story graph", nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("BardicGraphRefresh", function()
    require("bardic.graph_view").refresh()
  end, { desc = "Refresh the visible Bardic story graph" })

  vim.api.nvim_create_user_command("BardicGraphExport", function(args)
    require("bardic.graph_view").export(args.args ~= "" and args.args or nil)
  end, { desc = "Export the Bardic story graph", nargs = "?", complete = "file" })

  vim.api.nvim_create_user_command("BardicPreview", function(args)
    local state = nil
    if args.args ~= "" then
      local ok, decoded = pcall(vim.json.decode, args.args)
      if not ok then
        notify("Invalid JSON state: " .. tostring(decoded), vim.log.levels.ERROR)
        return
      end
      state = decoded
    end
    require("bardic.preview").passage(nil, state)
  end, { desc = "Preview the Bardic passage under the cursor", nargs = "?" })

  local group = vim.api.nvim_create_augroup("nvim_bardic", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    pattern = "*.bard",
    callback = function(args)
      if require("bardic.config").get().auto_refresh_graph then
        local view = require("bardic.graph_view")
        if view.state and view.state.file == args.file then
          view.refresh()
        end
      end
    end,
  })
end

return M
