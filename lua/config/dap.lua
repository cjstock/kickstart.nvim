local dap = require 'dap'
local dv = require 'dap-view'

require('mason-nvim-dap').setup {
  ensure_installed = { 'codelldb' },
  handlers = {
    -- Register only the adapter; skip mason-nvim-dap's default configurations
    -- so dap.configurations.rust contains exactly our static entry plus
    -- whatever load_launchjs() pulls from .vscode/launch.json.
    codelldb = function(config)
      dap.adapters.codelldb = config.adapters
    end,
  },
}

dv.setup {}

dap.listeners.before.attach['dap-view-config'] = function()
  dv.open()
end
dap.listeners.before.launch['dap-view-config'] = function()
  dv.open()
end
dap.listeners.before.event_terminated['dap-view-config'] = function()
  dv.close()
end
dap.listeners.before.event_exited['dap-view-config'] = function()
  dv.close()
end

local rust = require 'config.dap_rust'

-- Shared shape for every Rust launch config. `sourceLanguages` turns on
-- codelldb's Rust formatters, so String/Vec/HashMap render readably.
local function rust_cfg(name, spec)
  return vim.tbl_extend('error', {
    name = name,
    type = 'codelldb',
    request = 'launch',
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    sourceLanguages = { 'rust' },
    env = rust.dotenv,
    -- Flip to 'integrated' if you want test stdout in a terminal window
    -- rather than the dap-view console.
    terminal = 'console',
  }, spec)
end

-- Each test config resolves `program` (build + locate the binary) and `args`
-- (the libtest filter) independently; dap_rust memoizes so cargo runs once.
local function test_cfg(name, scope)
  return rust_cfg(name, {
    program = function()
      return rust.test_program(scope) or dap.ABORT
    end,
    args = function()
      return rust.test_args(scope)
    end,
  })
end

dap.configurations.rust = {
  test_cfg('Test: nearest (cursor)', 'nearest'),
  test_cfg('Test: all in this file', 'file'),
  test_cfg('Test: all in this target', 'target'),

  rust_cfg('Run binary: zero2prod', {
    program = function()
      return rust.build({ 'build', '--bin', 'zero2prod' }, false) or dap.ABORT
    end,
    args = {},
  }),

  rust_cfg('Launch (prompt for exe)', {
    program = function()
      return vim.fn.input('Path to executable: ', rust.root() .. '/target/debug/', 'file')
    end,
  }),
}

-- Auto-load .vscode/launch.json from the cwd. Entries with type = "codelldb"
-- (or "lldb") are registered under dap.configurations.rust.
-- require('dap.ext.vscode').load_launchjs(nil, { codelldb = { 'rust' } })

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = 'DAP: ' .. desc })
end

map('<leader>dc', dap.continue, '[C]ontinue / start')
map('<leader>db', dap.toggle_breakpoint, 'Toggle [B]reakpoint')
map('<leader>dB', function()
  dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
end, 'Conditional [B]reakpoint')
map('<leader>dn', dap.step_over, '[N]ext (step over)')
map('<leader>di', dap.step_into, 'Step [I]nto')
map('<leader>do', dap.step_out, 'Step [O]ut')
map('<leader>dr', dap.run_last, '[R]un last')
map('<leader>dt', dap.terminate, '[T]erminate')
map('<leader>dv', dv.toggle, 'Toggle dap-[V]iew')

-- Jump straight to the test under the cursor, skipping the config picker.
map('<leader>dT', function()
  dap.run(dap.configurations.rust[1])
end, 'Debug nearest [T]est')

vim.keymap.set({ 'n', 'v' }, '<leader>de', function()
  dv.eval()
end, { desc = 'DAP: [E]val expression' })
