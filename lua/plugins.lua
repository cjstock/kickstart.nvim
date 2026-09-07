-- Plugin manager: built-in vim.pack (Neovim 0.12+). Lockfile at
-- ~/.config/nvim/nvim-pack-lock.json. Update with :lua vim.pack.update().

local gh = function(repo)
  return 'https://github.com/' .. repo
end

local plugins = {
  -- Core libs & UI
  { src = gh 'nvim-lua/plenary.nvim' },
  { src = gh 'nvim-tree/nvim-web-devicons' },
  { src = gh 'echasnovski/mini.nvim' },

  -- Editing
  { src = gh 'NMAC427/guess-indent.nvim' },
  { src = gh 'windwp/nvim-autopairs' },
  { src = gh 'lukas-reineke/indent-blankline.nvim' },
  { src = gh 'folke/todo-comments.nvim' },

  -- Navigation / files / git
  { src = gh 'lewis6991/gitsigns.nvim' },
  { src = gh 'folke/which-key.nvim' },
  { src = gh 'stevearc/oil.nvim' },

  -- Fuzzy finder
  { src = gh 'ibhagwan/fzf-lua' },

  -- Completion
  { src = gh 'saghen/blink.cmp', version = vim.version.range '^1' },

  -- LSP helpers
  { src = gh 'mason-org/mason.nvim' },
  { src = gh 'neovim/nvim-lspconfig' },
  { src = gh 'mason-org/mason-lspconfig.nvim' },
  { src = gh 'WhoIsSethDaniel/mason-tool-installer.nvim' },
  { src = gh 'folke/lazydev.nvim' },
  { src = gh 'j-hui/fidget.nvim' },

  -- Debugging (DAP)
  { src = gh 'mfussenegger/nvim-dap' },
  { src = gh 'igorlfs/nvim-dap-view' },
  { src = gh 'jay-babu/mason-nvim-dap.nvim' },

  -- Formatting
  { src = gh 'stevearc/conform.nvim' },

  -- Markdown
  { src = gh 'MeanderingProgrammer/render-markdown.nvim' },
  { src = gh 'selimacerbas/live-server.nvim' },
  { src = gh 'selimacerbas/markdown-preview.nvim' },

  -- Treesitter (main branch; new API)
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },

  -- Database
  { src = gh 'tpope/vim-dadbod' },
  { src = gh 'tpope/vim-dotenv' },
  { src = gh 'kristijanhusak/vim-dadbod-ui' },
  { src = gh 'kristijanhusak/vim-dadbod-completion' },

  -- LaTeX
  { src = gh 'lervag/vimtex' },

  -- Theme / colorscheme
  -- base46 powers the DMS-generated colors/dms.lua (dank material shell
  -- dynamic theming). It must be present or colors/dms.lua bails out.
  { src = gh 'AvengeMedia/base46' },
}

vim.pack.add(plugins)
