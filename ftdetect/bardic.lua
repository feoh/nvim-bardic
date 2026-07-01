vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.bard",
  callback = function(args)
    vim.bo[args.buf].filetype = "bardic"
  end,
})
