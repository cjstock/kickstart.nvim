local dap = require('dap')
local dv = require('dap-view')

require('mason-nvim-dap').setup({
  ensure_installed = { 'codelldb' },
  handlers = {
    -- Register only the adapter; skip mason-nvim-dap's default configurations
    -- so dap.configurations.rust contains exactly our static entry plus
    -- whatever load_launchjs() pulls from .vscode/launch.json.
    codelldb = function(config) dap.adapters.codelldb = config.adapters end,
  },
})

dv.setup({})

dap.listeners.before.attach['dap-view-config'] = function() dv.open() end
dap.listeners.before.launch['dap-view-config'] = function() dv.open() end
dap.listeners.before.event_terminated['dap-view-config'] = function() dv.close() end
dap.listeners.before.event_exited['dap-view-config'] = function() dv.close() end

dap.configurations.rust = {
  {
    name = 'Launch (prompt for exe)',
    type = 'codelldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/target/debug/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
  },
}

-- Auto-load .vscode/launch.json from the cwd. Entries with type = "codelldb"
-- (or "lldb") are registered under dap.configurations.rust.
require('dap.ext.vscode').load_launchjs(nil, { codelldb = { 'rust' } })

local map = function(lhs, rhs, desc)
  vim.keymap.set('n', lhs, rhs, { desc = 'DAP: ' .. desc })
end

map('<leader>dc', dap.continue, '[C]ontinue / start')
map('<leader>db', dap.toggle_breakpoint, 'Toggle [B]reakpoint')
map('<leader>dB', function()
  dap.set_breakpoint(vim.fn.input('Breakpoint condition: '))
end, 'Conditional [B]reakpoint')
map('<leader>dn', dap.step_over, '[N]ext (step over)')
map('<leader>di', dap.step_into, 'Step [I]nto')
map('<leader>do', dap.step_out, 'Step [O]ut')
map('<leader>dr', dap.run_last, '[R]un last')
map('<leader>dt', dap.terminate, '[T]erminate')
map('<leader>dv', dv.toggle, 'Toggle dap-[V]iew')

vim.keymap.set({ 'n', 'v' }, '<leader>de', function() dv.eval() end, { desc = 'DAP: [E]val expression' })
