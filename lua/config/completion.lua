vim.opt.completeopt = { 'menu', 'menuone', 'noinsert', 'noselect', 'fuzzy', 'popup' }
vim.opt.shortmess:append('c')

vim.keymap.set({ 'i', 's' }, '<Tab>', function()
  if vim.snippet.active({ direction = 1 }) then
    return '<Cmd>lua vim.snippet.jump(1)<CR>'
  end
  return '<Tab>'
end, { expr = true })

vim.keymap.set({ 'i', 's' }, '<S-Tab>', function()
  if vim.snippet.active({ direction = -1 }) then
    return '<Cmd>lua vim.snippet.jump(-1)<CR>'
  end
  return '<S-Tab>'
end, { expr = true })

vim.keymap.set('i', '<C-Space>', function()
  vim.lsp.completion.get()
end)
