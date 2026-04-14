vim.lsp.enable({ 'lua_ls', 'rust_analyzer' })

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
    local tb = require('telescope.builtin')

    map('grr', tb.lsp_references, '[G]oto [R]eferences')
    map('gri', tb.lsp_implementations, '[G]oto [I]mplementation')
    map('grd', tb.lsp_definitions, '[G]oto [D]efinition')
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')
    map('grt', tb.lsp_type_definitions, '[G]oto [T]ype Definition')
    map('gO', tb.lsp_document_symbols, 'Open Document Symbols')
    map('gW', tb.lsp_dynamic_workspace_symbols, 'Open Workspace Symbols')

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

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion, event.buf) then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end

    if client:supports_method('textDocument/inlineCompletion', event.buf) then
      pcall(vim.lsp.inline_completion.enable)
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_foldingRange, event.buf) then
      vim.wo[0][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
      vim.wo[0][0].foldmethod = 'expr'
    end
  end,
})
