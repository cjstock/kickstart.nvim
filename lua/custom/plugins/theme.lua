local theme_file = vim.fn.expand '~/.config/omarchy/current/theme/neovim.lua'

-- helper: copy opts except some keys
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

if vim.fn.filereadable(theme_file) == 1 then
  local spec = dofile(theme_file)

  -- normalize: ensure always a list of plugins
  if spec[1] and type(spec[1]) == 'string' then
    spec = { spec }
  end

  local cleaned = {}
  local lazyvim_opts = {}

  for _, plugin in ipairs(spec) do
    if plugin[1] == 'LazyVim/LazyVim' then
      lazyvim_opts = plugin.opts or {}
    else
      table.insert(cleaned, plugin)
    end
  end

  local colorscheme = lazyvim_opts.colorscheme
  local rest_opts = without(lazyvim_opts, 'colorscheme')

  -- Special cases: ensure Catppuccin or Tokyonight plugin is included if missing
  if colorscheme and colorscheme:match '^catppuccin' then
    local found = false
    for _, p in ipairs(cleaned) do
      if p[1]:match 'catppuccin' then
        found = true
        break
      end
    end
    if not found then
      table.insert(cleaned, { 'catppuccin/nvim', name = 'catppuccin' })
    end
  elseif colorscheme == 'tokyonight' then
    local found = false
    for _, p in ipairs(cleaned) do
      if p[1]:match 'tokyonight' then
        found = true
        break
      end
    end
    if not found then
      table.insert(cleaned, { 'folke/tokyonight.nvim' })
    end
  end

  local function set_theme()
    -- special handling for catppuccin / tokyonight setup
    if next(rest_opts) and colorscheme then
      local theme_name = colorscheme:gsub('%-.*', '')
      if theme_name == 'catppuccin' or theme_name == 'tokyonight' then
        local ok, mod = pcall(require, theme_name)
        if ok and type(mod.setup) == 'function' then
          mod.setup(rest_opts)
        end
      end
    end

    -- apply colorscheme unless first plugin has its own config
    local first = cleaned[1]
    if (not first or type(first.config) ~= 'function') and colorscheme then
      pcall(vim.cmd.colorscheme, colorscheme)
    end
  end

  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = set_theme,
  })

  return cleaned
end

-- fallback if no theme symlink
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
