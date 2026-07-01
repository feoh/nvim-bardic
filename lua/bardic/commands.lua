local M = {}

local created = false

function M.setup()
  if created then
    return
  end
  created = true

  vim.api.nvim_create_user_command("BardicCompile", function()
    vim.notify("BardicCompile is not implemented yet", vim.log.levels.WARN)
  end, { desc = "Compile the current Bardic story" })

  vim.api.nvim_create_user_command("BardicLint", function()
    vim.notify("BardicLint is not implemented yet", vim.log.levels.WARN)
  end, { desc = "Lint the current Bardic story" })

  vim.api.nvim_create_user_command("BardicGraph", function()
    vim.notify("BardicGraph is not implemented yet", vim.log.levels.WARN)
  end, { desc = "Show the Bardic story graph" })

  vim.api.nvim_create_user_command("BardicGraphRefresh", function()
    vim.notify("BardicGraphRefresh is not implemented yet", vim.log.levels.WARN)
  end, { desc = "Refresh the visible Bardic story graph" })

  vim.api.nvim_create_user_command("BardicGraphExport", function()
    vim.notify("BardicGraphExport is not implemented yet", vim.log.levels.WARN)
  end, { desc = "Export the Bardic story graph" })

  vim.api.nvim_create_user_command("BardicPreview", function()
    vim.notify("BardicPreview is not implemented yet", vim.log.levels.WARN)
  end, { desc = "Preview the Bardic passage under the cursor" })
end

return M
