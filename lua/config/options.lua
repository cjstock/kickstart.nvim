vim.g.have_nerd_font = false

vim.o.number = true
vim.o.relativenumber = true
vim.o.mouse = 'a'
vim.o.winborder = 'rounded'
vim.o.showmode = false
vim.schedule(function()
  vim.o.clipboard = 'unnamedplus'
end)
vim.o.breakindent = true
vim.o.undofile = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.signcolumn = 'yes'
vim.o.updatetime = 250
vim.o.timeoutlen = 300
vim.o.splitright = true
vim.o.splitbelow = true
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.o.inccommand = 'split'
vim.o.cursorline = true
vim.o.scrolloff = 10
vim.o.confirm = true

vim.opt.tabstop = 4 -- Number of spaces a <Tab> counts for
vim.opt.shiftwidth = 4 -- Number of spaces for each step of (auto)indent
vim.opt.expandtab = true -- Convert tabs to spaces
vim.opt.smartindent = true -- Make indents smarter

vim.g.db_ui_winwidth = 80
