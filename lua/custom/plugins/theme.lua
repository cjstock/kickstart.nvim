-- Loads the current omarchy theme spec and watches for theme changes.
-- On theme change (detected via libuv fs_event on ~/.config/omarchy/current/),
-- fires User LazyReload, which custom.plugins.omarchy_theme_hotreload handles.

local theme_file = vim.fn.expand '~/.config/omarchy/current/theme/neovim.lua'
local watch_dir = vim.fn.expand '~/.config/omarchy/current/'

local function without(tbl, ...)
  local copy, skip = {}, {}
  for _, k in ipairs { ... } do
    skip[k] = true
  end
  for k, v in pairs(tbl or {}) do
    if not skip[k] then
      copy[k] = v
    end
  end
  return copy
end

-- Strip the LazyVim/LazyVim marker entry (kickstart can't load it) and return
-- the remaining plugin specs plus the colorscheme name extracted from its opts.
local function clean_spec(spec)
  local cleaned, lazyvim_opts = {}, {}
  for _, plugin in ipairs(spec) do
    if plugin[1] == 'LazyVim/LazyVim' then
      lazyvim_opts = plugin.opts or {}
    else
      table.insert(cleaned, plugin)
    end
  end
  return cleaned, lazyvim_opts.colorscheme, without(lazyvim_opts, 'colorscheme')
end

-- Fire User LazyReload on theme change. Watch the parent directory so the
-- watcher survives omarchy's atomic `rm -rf current/theme && mv next-theme
-- current/theme` swap (which would invalidate a single-file watch).
local fs_event
local function arm_watcher()
  if fs_event then
    fs_event:stop()
    fs_event:close()
  end
  fs_event = vim.uv.new_fs_event()
  if not fs_event then
    return
  end
  fs_event:start(watch_dir, { recursive = false }, function(err, filename, _events)
    if err or filename ~= 'theme.name' then
      return
    end
    vim.schedule(function()
      vim.api.nvim_exec_autocmds('User', { pattern = 'LazyReload', modeline = false })
      arm_watcher()
    end)
  end)
end
arm_watcher()

if vim.fn.filereadable(theme_file) == 1 then
  local spec = dofile(theme_file)
  local cleaned, colorscheme, rest_opts = clean_spec(spec)

  local function set_theme()
    if next(rest_opts) and colorscheme then
      local theme_name = colorscheme:gsub('%-.*', '')
      if theme_name == 'catppuccin' or theme_name == 'tokyonight' then
        local ok, mod = pcall(require, theme_name)
        if ok and type(mod.setup) == 'function' then
          mod.setup(rest_opts)
        end
      end
    end
    local first = cleaned[1]
    if (not first or type(first.config) ~= 'function') and colorscheme then
      pcall(vim.cmd.colorscheme, colorscheme)
    end
  end

  vim.api.nvim_create_autocmd('VimEnter', { once = true, callback = set_theme })
  return cleaned
end

-- Fallback: no omarchy theme file present.
return {
  {
    'ellisonleao/gruvbox.nvim',
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme 'gruvbox'
    end,
  },
}
