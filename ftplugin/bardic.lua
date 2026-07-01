vim.opt_local.commentstring = "# %s"
vim.opt_local.wrap = true
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "v:lua.require'bardic.fold'.foldexpr(v:lnum)"
vim.opt_local.foldtext = "v:lua.require'bardic.fold'.foldtext()"
