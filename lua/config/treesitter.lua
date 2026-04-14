local ensure_installed = {
  -- nvim-treesitter main ships queries that can be newer than the parsers
  -- bundled with nvim core (c, lua, vim, vimdoc, markdown, query). Install
  -- matching parsers for all of them so highlighting queries don't fail.
  'lua',
  'vim',
  'vimdoc',
  'markdown',
  'markdown_inline',
  'query',
  'bash',
  'diff',
  'html',
  'javascript',
  'typescript',
  'json',
  'yaml',
  'toml',
  'python',
  'rust',
  'regex',
  'sql',
  'css',
  'luadoc',
}

local ok, ts = pcall(require, 'nvim-treesitter')
if ok and ts.install then
  local installed = {}
  for _, l in ipairs(ts.get_installed and ts.get_installed 'parsers' or {}) do
    installed[l] = true
  end
  local missing = {}
  for _, l in ipairs(ensure_installed) do
    if not installed[l] then
      missing[#missing + 1] = l
    end
  end
  if #missing > 0 then
    vim.notify('nvim-treesitter: installing ' .. table.concat(missing, ', '))
    local task = ts.install(missing, { summary = true })
    if task and task.wait then
      task:wait(300000)
    end
  end
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('user-treesitter-start', { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
    if not lang then
      return
    end
    local ok_start = pcall(vim.treesitter.start, ev.buf, lang)
    if ok_start then
      vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})
