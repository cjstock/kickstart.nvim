require('mason').setup()

require('mason-tool-installer').setup({
  ensure_installed = {
    'lua_ls',
    'rust_analyzer',
    'bashls',
    'dockerls',
    'postgres-language-server',
    'marksman',
    'yamlls',
    'stylua',
    'codelldb',
  },
})

require('mason-lspconfig').setup({
  automatic_enable = true,
})

vim.diagnostic.config({
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  } or {},
  virtual_text = { source = 'if_many', spacing = 2 },
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buf = event.buf, desc = 'LSP: ' .. desc })
    end
    local fzf = require('fzf-lua')

    map('grr', fzf.lsp_references, '[G]oto [R]eferences')
    map('gri', fzf.lsp_implementations, '[G]oto [I]mplementation')
    map('grd', fzf.lsp_definitions, '[G]oto [D]efinition')
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('grt', fzf.lsp_typedefs, '[G]oto [T]ype Definition')
    map('gO', fzf.lsp_document_symbols, 'Open Document Symbols')
    map('gW', fzf.lsp_live_workspace_symbols, 'Open Workspace Symbols')

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then return end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
      local hl = vim.api.nvim_create_augroup('user-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf, group = hl, callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf, group = hl, callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('user-lsp-detach', { clear = true }),
        callback = function(ev2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds({ group = 'user-lsp-highlight', buffer = ev2.buf })
        end,
      })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
      end, '[T]oggle Inlay [H]ints')
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange, event.buf) then
      vim.wo[0][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end
  end,
})
