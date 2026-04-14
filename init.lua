vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

require('config.options')
require('config.keymaps')
require('config.autocmds')

require('plugins')
require('config.plugins_setup')

require('config.treesitter')
require('config.completion')
require('config.folding')
require('config.lsp')
require('config.theme').setup()

-- vim: ts=2 sts=2 sw=2 et
