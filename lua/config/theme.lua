-- Omarchy theme integration for vim.pack:
-- * On startup, read ~/.config/omarchy/current/theme/neovim.lua, extract the
--   colorscheme name and any setup opts, apply them.
-- * Watch ~/.config/omarchy/current/ for theme.name changes and hot-reload.
-- Original (lazy.nvim-based) implementation lived in
-- custom/plugins/{theme,omarchy_theme_hotreload}.lua.

local M = {}

local theme_file = vim.fn.expand('~/.config/omarchy/current/theme/neovim.lua')
local watch_dir = vim.fn.expand('~/.config/omarchy/current/')

local function without(tbl, ...)
  local copy, skip = {}, {}
  for _, k in ipairs({ ... }) do skip[k] = true end
  for k, v in pairs(tbl or {}) do
    if not skip[k] then copy[k] = v end
  end
  return copy
end

-- LazyVim-style spec: { { 'LazyVim/LazyVim', opts = { colorscheme = '...' } }, { 'owner/repo', opts = {...}, config = fn }, ... }
-- Returns: first_plugin_spec (the colorscheme plugin), colorscheme name, remaining LazyVim opts minus colorscheme.
local function parse_spec(spec)
  local first_plugin, lazyvim_opts = nil, {}
  for _, plugin in ipairs(spec) do
    if plugin[1] == 'LazyVim/LazyVim' then
      lazyvim_opts = plugin.opts or {}
    elseif not first_plugin then
      first_plugin = plugin
    end
  end
  return first_plugin, lazyvim_opts.colorscheme, without(lazyvim_opts, 'colorscheme')
end

-- Plugin dir for a vim.pack-installed plugin. Name is the last segment of 'owner/repo'.
local function pack_plugin_dir(name_or_repo)
  local name = name_or_repo:match('[^/]+$')
  return vim.fn.stdpath('data') .. '/site/pack/core/opt/' .. name
end

-- Walk lua modules under a directory and wipe them from package.loaded/preload
-- so that a plugin's setup() re-evaluates with fresh palette data on next require.
local function unload_modules_under(dir)
  if vim.fn.isdirectory(dir) ~= 1 then return end
  local files = vim.fn.globpath(dir, '**/*.lua', true, true)
  for _, file in ipairs(files) do
    local rel = file:sub(#dir + 2):gsub('%.lua$', ''):gsub('/', '.')
    rel = rel:gsub('%.init$', '')
    package.loaded[rel] = nil
    package.preload[rel] = nil
  end
end

local function apply_theme_spec(spec)
  local first_plugin, colorscheme, rest_opts = parse_spec(spec)
  if not colorscheme then return end

  -- Ristretto-style themes: run setup() from LazyVim opts before :colorscheme.
  if next(rest_opts) then
    local theme_mod = colorscheme:gsub('%-.*', '')
    if theme_mod == 'catppuccin' or theme_mod == 'tokyonight' then
      local ok, mod = pcall(require, theme_mod)
      if ok and type(mod.setup) == 'function' then
        mod.setup(rest_opts)
      end
    end
  end

  -- Some theme plugin specs carry a config() hook that calls setup(...) itself.
  if first_plugin and type(first_plugin.config) == 'function' then
    pcall(first_plugin.config)
  else
    pcall(vim.cmd.colorscheme, colorscheme)
  end
end

local function reload()
  if vim.fn.filereadable(theme_file) ~= 1 then return end
  local ok, spec = pcall(dofile, theme_file)
  if not ok or type(spec) ~= 'table' then return end

  vim.cmd('highlight clear')
  if vim.fn.exists('syntax_on') == 1 then
    vim.cmd('syntax reset')
  end
  vim.o.background = 'dark'

  -- Find first non-LazyVim plugin spec, unload its modules before apply.
  for _, plugin in ipairs(spec) do
    if plugin[1] and plugin[1] ~= 'LazyVim/LazyVim' then
      local dir = pack_plugin_dir(plugin.name or plugin[1])
      unload_modules_under(dir .. '/lua')
      break
    end
  end

  vim.defer_fn(function()
    apply_theme_spec(spec)
    vim.cmd('redraw!')
    local transparency_file = vim.fn.stdpath('config') .. '/plugin/after/transparency.lua'
    if vim.fn.filereadable(transparency_file) == 1 then
      vim.defer_fn(function()
        vim.cmd.source(transparency_file)
        vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
        vim.api.nvim_exec_autocmds('VimEnter', { modeline = false })
        vim.cmd('redraw!')
      end, 5)
    else
      vim.api.nvim_exec_autocmds('ColorScheme', { modeline = false })
      vim.cmd('redraw!')
    end
  end, 5)
end

local fs_event
local function arm_watcher()
  if fs_event then
    fs_event:stop()
    fs_event:close()
  end
  fs_event = vim.uv.new_fs_event()
  if not fs_event then return end
  fs_event:start(watch_dir, { recursive = false }, function(err, filename, _events)
    if err or filename ~= 'theme.name' then return end
    vim.schedule(function()
      reload()
      arm_watcher()
    end)
  end)
end

function M.setup()
  arm_watcher()
  if vim.fn.filereadable(theme_file) ~= 1 then
    pcall(vim.cmd.colorscheme, 'habamax')
    return
  end
  local ok, spec = pcall(dofile, theme_file)
  if not ok or type(spec) ~= 'table' then return end
  vim.api.nvim_create_autocmd('VimEnter', {
    once = true,
    callback = function() apply_theme_spec(spec) end,
  })
end

return M
