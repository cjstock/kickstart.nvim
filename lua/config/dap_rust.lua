-- Rust/Cargo helpers for nvim-dap.
--
-- Cargo emits test binaries as target/debug/deps/<target>-<hash>, so the path
-- can never be hardcoded. Everything here builds with --message-format=json and
-- reads the `executable` field out of the compiler-artifact messages.

local M = {}

local function root()
  return vim.fs.root(0, 'Cargo.toml') or vim.fn.getcwd()
end
M.root = root

-- Read .env into a table so the debuggee sees DATABASE_URL etc.
local function dotenv()
  local env = {}
  local f = io.open(root() .. '/.env', 'r')
  if not f then
    return env
  end
  for line in f:lines() do
    if not line:match '^%s*#' then
      local k, v = line:match '^%s*([%w_]+)%s*=%s*(.-)%s*$'
      if k then
        v = v:gsub('^"(.*)"$', '%1'):gsub("^'(.*)'$", '%1')
        env[k] = v
      end
    end
  end
  f:close()
  return env
end
M.dotenv = dotenv

-- Cargo.toml sets [profile.test] opt-level = 3, which shreds locals and inlines
-- frames. Override it per-invocation instead of editing the manifest.
local build_env = {
  CARGO_PROFILE_TEST_OPT_LEVEL = '0',
  CARGO_PROFILE_TEST_DEBUG = '2',
}

--- Run cargo and return the executable artifact it produced.
--- @param args string[] cargo subcommand + flags, e.g. { 'test', '--no-run', '--lib' }
--- @param want_test boolean true for a test harness, false for a plain binary
--- @return string|nil path
local function build(args, want_test)
  local cmd = vim.list_extend(vim.list_slice(args), { '--message-format=json' })
  table.insert(cmd, 1, 'cargo')

  vim.notify('cargo ' .. table.concat(args, ' '), vim.log.levels.INFO)
  local res = vim.system(cmd, { cwd = root(), env = build_env, text = true }):wait()

  -- Only artifacts from *this* manifest; dependency crates also emit
  -- compiler-artifact messages and would otherwise be picked up.
  local manifest = root() .. '/Cargo.toml'
  local exes = {}
  for line in (res.stdout or ''):gmatch '[^\n]+' do
    local ok, msg = pcall(vim.json.decode, line)
    if
      ok
      and msg.reason == 'compiler-artifact'
      and type(msg.executable) == 'string'
      and msg.manifest_path == manifest
      -- `cargo test --test api` also builds the bin; profile.test tells the
      -- test harness apart from it. Without this the pick is order-dependent.
      and (msg.profile or {}).test == (want_test == true)
    then
      table.insert(exes, msg.executable)
    end
  end

  if #exes == 0 then
    vim.notify('cargo produced no executable:\n' .. (res.stderr or ''), vim.log.levels.ERROR)
    return nil
  elseif #exes > 1 then
    vim.notify('cargo produced several executables:\n  ' .. table.concat(exes, '\n  '), vim.log.levels.WARN)
  end
  return exes[1]
end
M.build = build

-- Map a buffer path to the cargo test target that contains it.
local function target_for(rel)
  if rel == 'src/main.rs' then
    return { '--bins' }
  elseif rel:match '^src/' then
    return { '--lib' }
  end
  local t = rel:match '^tests/([^/]+)'
  if t then
    return { '--test', (t:gsub('%.rs$', '')) }
  end
end

-- Module path implied by the file's location within its target.
local function module_prefix(rel)
  local p
  if rel:match '^src/' then
    p = rel:gsub('^src/', ''):gsub('%.rs$', '')
    if p == 'lib' or p == 'main' then
      return {}
    end
  else
    p = rel:gsub('^tests/', ''):gsub('%.rs$', '')
    local _, rest = p:match '^([^/]+)/(.*)$'
    if not rest or rest == 'main' then
      return {}
    end
    p = rest
  end
  p = p:gsub('/mod$', '')
  return vim.split(p, '/')
end

-- Walk up the treesitter tree from the cursor: nearest #[test] fn + its mods.
local function test_at_cursor()
  local node = vim.treesitter.get_node()
  local fn, mods = nil, {}
  while node do
    local t = node:type()
    if t == 'function_item' and not fn then
      local n = node:field('name')[1]
      if n then
        fn = vim.treesitter.get_node_text(n, 0)
      end
    elseif t == 'mod_item' then
      local n = node:field('name')[1]
      if n then
        table.insert(mods, 1, vim.treesitter.get_node_text(n, 0))
      end
    end
    node = node:parent()
  end
  return fn, mods
end

--- Build the test binary for the current buffer and return program, args.
--- @param scope 'nearest'|'file'|'target'
local function test_spec(scope)
  local path = vim.api.nvim_buf_get_name(0)
  local rel = path:sub(#root() + 2)
  local target = target_for(rel)
  if not target then
    vim.notify('Not a Rust source or test file: ' .. rel, vim.log.levels.ERROR)
    return nil
  end

  local filter = {}
  local prefix = module_prefix(rel)
  if scope == 'nearest' then
    local fn, mods = test_at_cursor()
    if not fn then
      vim.notify('No test function under the cursor', vim.log.levels.ERROR)
      return nil
    end
    local full = vim.list_extend(vim.list_extend({}, prefix), mods)
    table.insert(full, fn)
    filter = { table.concat(full, '::'), '--exact' }
  elseif scope == 'file' and #prefix > 0 then
    filter = { table.concat(prefix, '::') }
  end

  local program = M.build(vim.list_extend({ 'test', '--no-run' }, target), true)
  if not program then
    return nil
  end

  -- A filter that matches nothing makes libtest exit 0 immediately, so the
  -- debugger detaches with no explanation. Ask the binary up front instead.
  if filter[1] and not M.matches(program, filter[1], filter[2] == '--exact') then
    return nil
  end

  return program, vim.list_extend(filter, { '--nocapture', '--test-threads=1' })
end

--- Does `pattern` select at least one test in the built binary?
function M.matches(program, pattern, exact)
  local res = vim.system({ program, '--list' }, { cwd = root(), text = true }):wait()
  local names, hit = {}, false
  for line in (res.stdout or ''):gmatch '[^\n]+' do
    local name = line:match '^(.*): test$'
    if name then
      table.insert(names, name)
      if (exact and name == pattern) or (not exact and name:find(pattern, 1, true)) then
        hit = true
      end
    end
  end
  if not hit then
    local near = vim.tbl_filter(function(n)
      return n:find(pattern:match '[^:]*$' or '', 1, true) ~= nil
    end, names)
    local msg = ('No test matches "%s"'):format(pattern)
    if #near > 0 then
      msg = msg .. '\n\nDid you mean:\n  ' .. table.concat(near, '\n  ')
    end
    vim.notify(msg, vim.log.levels.ERROR)
  end
  return hit
end

-- nvim-dap evaluates each config field independently and in unspecified order,
-- so `program` and `args` are two separate callbacks. Serve both from one build
-- by handing the computed spec to exactly one extra consumer before expiring.
local memo = { key = nil, uses = 0 }

local function spec(scope)
  local key = table.concat({
    scope,
    vim.api.nvim_get_current_buf(),
    vim.api.nvim_win_get_cursor(0)[1],
  }, ':')
  if memo.key == key and memo.uses > 0 then
    memo.uses = memo.uses - 1
    return memo.program, memo.args
  end
  local program, args = test_spec(scope)
  memo = { key = key, program = program, args = args, uses = 1 }
  return program, args
end

function M.test_program(scope)
  return (spec(scope))
end

function M.test_args(scope)
  local _, args = spec(scope)
  return args or {}
end

return M
