require('blink.cmp').setup({
  keymap = {
    preset = 'default',
  },

  appearance = {
    nerd_font_variant = 'mono',
  },

  completion = {
    documentation = { auto_show = true, auto_show_delay_ms = 500 },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets', 'lazydev', 'buffer' },
    providers = {
      lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
      dadbod = { name = 'Dadbod', module = 'vim_dadbod_completion.blink' },
    },
    per_filetype = {
      sql = { 'snippets', 'dadbod', 'buffer' },
    },
  },

  fuzzy = { implementation = 'lua' },

  signature = { enabled = true },
})
