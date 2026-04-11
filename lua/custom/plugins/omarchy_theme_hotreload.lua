-- Hot-reload omarchy theme on User LazyReload.
-- The event is fired by custom.plugins.theme's fs_event watcher when
-- ~/.config/omarchy/current/theme.name changes.
-- Adapted from /usr/share/omarchy-nvim/config/lua/plugins/omarchy-theme-hotreload.lua.
-- Difference from stock: re-dofiles ~/.config/omarchy/current/theme/neovim.lua
-- directly instead of require("plugins.theme"), since this kickstart config
-- strips the LazyVim/LazyVim marker before returning its spec.

return {
  {
    name = 'theme-hotreload',
    dir = vim.fn.stdpath 'config',
    lazy = false,
    priority = 1000,
    config = function()
      local theme_file = vim.fn.expand '~/.config/omarchy/current/theme/neovim.lua'

      vim.api.nvim_create_autocmd('User', {
        pattern = 'LazyReload',
        callback = function()
          vim.schedule(function()
            if vim.fn.filereadable(theme_file) ~= 1 then
              return
            end

            local ok, theme_spec = pcall(dofile, theme_file)
            if not ok or type(theme_spec) ~= 'table' then
              return
            end

            -- Find the first non-LazyVim plugin entry (the actual colorscheme
            -- plugin) and the colorscheme name from the LazyVim marker opts.
            local theme_plugin_name, first_plugin, colorscheme
            for _, spec in ipairs(theme_spec) do
              if spec[1] == 'LazyVim/LazyVim' then
                if spec.opts and spec.opts.colorscheme then
                  colorscheme = spec.opts.colorscheme
                end
              elseif not first_plugin then
                first_plugin = spec
                theme_plugin_name = spec.name or spec[1]
              end
            end

            if not colorscheme then
              return
            end

            -- Reset highlights so the new colorscheme starts from a clean slate.
            vim.cmd 'highlight clear'
            if vim.fn.exists 'syntax_on' then
              vim.cmd 'syntax reset'
            end
            -- Let the new colorscheme decide background; reset first so light
            -- themes can flip it.
            vim.o.background = 'dark'

            -- Force-unload the old theme plugin's lua modules so their setup()
            -- re-evaluates with fresh palette data on next require.
            if theme_plugin_name then
              local plugin = require('lazy.core.config').plugins[theme_plugin_name]
              if plugin and plugin.dir then
                local plugin_dir = plugin.dir .. '/lua'
                require('lazy.core.util').walkmods(plugin_dir, function(modname)
                  package.loaded[modname] = nil
                  package.preload[modname] = nil
                end)
              end
            end

            -- Ensure the new colorscheme's plugin is loaded.
            pcall(require('lazy.core.loader').colorscheme, colorscheme)

            vim.defer_fn(function()
              -- Ristretto-style themes carry a config() hook that calls
              -- setup({ filter = ... }) before :colorscheme. Run it explicitly.
              if first_plugin and type(first_plugin.config) == 'function' then
                pcall(first_plugin.config)
              else
                pcall(vim.cmd.colorscheme, colorscheme)
              end

              vim.cmd 'redraw!'

              -- Source transparency tweaks if the user has them (kickstart
              -- doesn't ship plugin/after/transparency.lua but stock
              -- omarchy-nvim does; support both).
              local transparency_file = vim.fn.stdpath 'config' .. '/plugin/after/transparency.lua'
              if vim.fn.filereadable(transparency_file) == 1 then
                vim.defer_fn(function()
                  vim.cmd.source(transparency_file)
                  vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
                  vim.api.nvim_exec_autocmds('VimEnter', { modeline = false })
                  vim.cmd 'redraw!'
                end, 5)
              else
                vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
                vim.cmd 'redraw!'
              end
            end, 5)
          end)
        end,
      })
    end,
  },
}
