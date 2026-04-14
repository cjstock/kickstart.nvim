vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('user-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

vim.api.nvim_create_autocmd('VimEnter', {
  callback = function() vim.cmd 'packadd! cfilter' end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'xml',
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.softtabstop = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help' },
  desc = 'Open help in vsplit',
  group = vim.api.nvim_create_augroup('user-help-vsplit', { clear = true }),
  callback = function() vim.cmd 'wincmd L' end,
})
