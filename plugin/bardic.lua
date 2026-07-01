if vim.g.loaded_nvim_bardic == 1 then
  return
end
vim.g.loaded_nvim_bardic = 1

-- Commands are registered eagerly with defaults so the plugin works without
-- explicit setup. Users may call require('bardic').setup({...}) to configure.
require("bardic").setup()
