local SCRIPTS_DIR = NH.PLUGIN_DIR .. '/script'
local FZ = SCRIPTS_DIR .. '/fz'
local LOCAL_BIN = vim.fn.expand('~/.local/bin')
local LINK_PATH = LOCAL_BIN .. '/fz'

-- Make sure it's executable
if vim.fn.executable(FZ) == 0 then
  os.execute('chmod +x ' .. vim.fn.shellescape(FZ))
  print('Run: chmod +x ' .. FZ)
end

local T, sink, util = {}, {}, {}
local TEMPNAME = vim.fn.tempname()

if vim.fn.executable('nnn') == 0 and vim.fn.executable('fzf') == 0 and vim.fn.executable('gitui') == 0 then return end

-- Keymap  --------------------------------------------------------------------
function util.setup()
  vim.keymap.set('n', '<Leader>e', T.explorer, { desc = 'Explorer' })
  vim.keymap.set('n', '<Leader>f', T.find_files, { desc = 'Files' })
  vim.keymap.set('n', '<Leader>F', T.git_files, { desc = 'Git files' })
  vim.keymap.set('n', '<Leader>N', T.grep_note, { desc = 'Search hl note' })

  vim.keymap.set('n', '<Leader>Q', T.open_win_qf('q'), { desc = 'Quickfix List' })
  vim.keymap.set('n', '<Leader>L', T.open_win_qf('l'), { desc = 'Location List' })

  vim.keymap.set('n', '<Leader>xs', T.run_shell, { desc = 'Run and open result shell cmd' })
  vim.keymap.set('n', '<Leader>xv', T.run_vim, { desc = 'Run and open result vim cmd' })

  vim.keymap.set({ 'n', 'x' }, '<Leader>g/', T.grep_global, { desc = 'Grep current cwd' })
  vim.keymap.set({ 'n', 'x' }, '<Leader>/', T.grep_buffer, { desc = 'Grep current file' })

  vim.keymap.set({ 'n', 't' }, '<F1>', T.term_1, { desc = 'term 1' })
  vim.keymap.set({ 'n', 't' }, '<F2>', T.term_2, { desc = 'term 2' })
  vim.keymap.set({ 'n', 't' }, '<F3>', T.term_3, { desc = 'term 3 (local)' })
  vim.keymap.set({ 'n', 't' }, '<F4>', T.gitui, { desc = 'Gitui' })
end

-- Sink ------------------------------------------------------------------------
function sink.edit_file(selected)
  for i, sel in ipairs(selected) do
    if vim.fn.isdirectory(sel) == 1 then
      if i == #selected then vim.cmd('edit ' .. vim.fn.fnameescape(sel)) end
    elseif vim.fn.filereadable(sel) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(sel))
    else
      vim.system({ 'fz', 'remove_recent_file', sel }, { text = true }, function(obj)
        if obj.code ~= 0 then print('Error: ' .. obj.stderr) end
      end)
      vim.notify('Cannot open: ' .. sel, vim.log.levels.WARN)
    end
  end
end

function sink.edit_or_sel_to_qf(selected)
  if #selected > 1 then
    sink.sel_to_qf(selected)
  else
    local filename, lnum = selected[1]:match('([^:]+):(%d+):%d+')
    if vim.fn.filereadable(filename) == 1 then vim.cmd('edit +' .. lnum .. ' ' .. vim.fn.fnameescape(filename)) end
  end
end

function sink.go_to_line(selected, query)
  local lnum = selected[1]:match('^(%d+):(.*)$')
  if query then vim.fn.setreg('/', query) end
  vim.cmd(lnum or 1)
end

function sink.sel_to_qf(selected)
  local qf_list = {}
  for _, item in ipairs(selected) do
    local filename, line, col, text = item:match('([^:]+):(%d+):(%d+):?(.*)$')
    table.insert(qf_list, {
      filename = filename,
      lnum = tonumber(line),
      col = tonumber(col),
      text = text,
    })
  end
  table.sort(
    qf_list,
    function(a, b)
      return a.filename == b.filename and (a.lnum == b.lnum and a.col < b.col or a.lnum < b.lnum)
        or a.filename < b.filename
    end
  )

  local last_nr = vim.fn.getqflist({ nr = 0 }).nr
  vim.fn.setqflist({}, ' ', {
    nr = last_nr,
    items = qf_list,
    title = 'QF',
  })
  vim.cmd('botright copen')
end

-- Util ------------------------------------------------------------------------
function util.is_valid_path(path)
  if not path or path == '' then return false end
  local stat = vim.uv.fs_stat(path)
  return stat and (stat.type == 'file' or stat.type == 'directory')
end

function util.is_root() return vim.uv.getuid() == 0 end

function util.get_visual_selection() return vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = 'v' })[1] end

function util.extra_hl(query)
  vim.schedule(function() vim.fn.matchadd('CurSearch', query) end)
end

function util.get_word_or_selection()
  return vim.fn.mode() == 'v' and util.get_visual_selection() or vim.fn.expand('<cword>')
end

function util.get_float_opts(size)
  local columns = vim.o.columns
  local lines = vim.o.lines

  local presets = {
    xl = { wr = 0.9, hr = 0.85, rr = 0.3, cr = 0.5 },
    sm = { wr = 0.6, hr = 0.5, rr = 0.5, cr = 0.5 },
    xs = { wr = 0.4, hr = 0.35, rr = 0.5, cr = 0.5 },
  }

  local cfg = presets[size] or presets.xl

  local width = math.floor(columns * cfg.wr)
  local height = math.floor(lines * cfg.hr)
  local row = math.floor((lines - height) * cfg.rr)
  local col = math.floor((columns - width) * cfg.cr)

  return {
    relative = 'editor',
    style = 'minimal',
    row = row,
    col = col,
    width = width,
    height = height,
    border = 'single',
    title = '',
    title_pos = 'center',
  }
end

function util.win_open(opts, buf_id)
  local prev_win_id = vim.api.nvim_get_current_win()
  if not util.valid_buf(buf_id) then buf_id = vim.api.nvim_create_buf(false, true) end

  local win_id = vim.api.nvim_open_win(buf_id, true, opts)

  local function close_win()
    if vim.api.nvim_win_is_valid(prev_win_id) then vim.api.nvim_set_current_win(prev_win_id) end
    if vim.api.nvim_buf_is_valid(buf_id) then vim.api.nvim_buf_delete(buf_id, { force = true }) end
  end

  return {
    win_id = win_id,
    buf_id = buf_id,
    prev_win_id = prev_win_id,
    close_win = close_win,
  }
end

function util.valid_win(win_id) return win_id and vim.api.nvim_win_is_valid(win_id) end
function util.valid_buf(buf_id) return buf_id and vim.api.nvim_buf_is_valid(buf_id) end

function util.buf_delete(buf_id)
  if util.valid_buf(buf_id) then pcall(vim.api.nvim_buf_delete, buf_id, { force = true }) end
end
function util.win_close(win_id)
  if util.valid_win(win_id) then pcall(vim.api.nvim_win_close, win_id, true) end
end
function util.win_focus(win_id)
  if util.valid_win(win_id) then pcall(vim.api.nvim_set_current_win, win_id) end
end

function util.get_query_arg(opts)
  for _, arg in ipairs(opts.args or {}) do
    local query = arg:match('%-%-query=[\'"](.-)[\'"]')
    if query then return query end
  end
  return nil
end

-- Optional: Create symlink to ~/.local/bin/fz if needed
function util.symlink_fz()
  local source, link_path = FZ, LINK_PATH
  local stat = vim.uv.fs_stat(link_path)

  if stat then
    local real = vim.uv.fs_readlink(link_path)

    if real then
      -- It's a symlink
      if real == source then
        print("✅ Symlink already correct: " .. link_path)
      else
        print("⚠️ Symlink exists but points to: " .. real)
        print("Skipping override to avoid conflict.")
      end
    else
      -- Exists but is NOT a symlink (regular file or dir)
      print("⚠️ Path exists and is not a symlink: " .. link_path)
      print("Skipping to avoid overwriting existing file.")
    end
  else
    -- Make sure ~/.local/bin exists
    vim.fn.mkdir(LOCAL_BIN, "p")

    -- Create symlink
    local cmd = string.format('ln -s %s %s', vim.fn.shellescape(source), vim.fn.shellescape(link_path))
    local ok = os.execute(cmd)

    if ok == true or ok == 0 then
      print("✅ Symlink created: " .. link_path .. " → " .. source)
    else
      print("❌ Failed to create symlink.")
    end
  end
end

-- Core ------------------------------------------------------------------------
function util.jobstart(opts)
  local win = util.win_open(opts.win)
  local query = util.get_query_arg(opts)

  vim.bo[win.buf_id].bufhidden = 'wipe'
  vim.bo[win.buf_id].buftype = 'nofile'

  local function callback()
    vim.defer_fn(function()
      if vim.fn.filereadable(TEMPNAME) == 1 then opts.sink(vim.fn.readfile(TEMPNAME), query) end
    end, 50)
  end

  vim.fn.jobstart(opts.args, {
    term = true,
    on_exit = function(_, status)
      win.close_win()
      if status == 0 then callback() end
    end,
  })
end

function util.fzf_cmd(opts)
  opts.cmd = string.format('%s %s', vim.fn.shellescape(FZ), opts.cmd)
  local cmd = opts.args and (opts.cmd .. ' ' .. opts.args) or opts.cmd
  local fzf_args = string.format('%s > "%s"', cmd, TEMPNAME)
  local args = { vim.o.shell, vim.o.shellcmdflag, fzf_args }

  util.jobstart({
    win = vim.tbl_deep_extend('force', util.get_float_opts(), { title = opts.title }),
    sink = opts.sink,
    args = args,
  })
end

function util.nnn_cmd(opts)
  local file = util.is_valid_path(opts.path) and opts.path
    or util.is_valid_path(vim.fn.expand('%:p')) and vim.fn.expand('%:p')
    or vim.uv.cwd()
  local nnn_args = ('nnn -G -c %q -p %q %q'):format(file, TEMPNAME, vim.fn.expand('%:p:h'))
  local args = { vim.o.shell, vim.o.shellcmdflag, nnn_args }

  util.jobstart({
    win = vim.tbl_deep_extend('force', util.get_float_opts('sm'), { title = opts.title }),
    sink = opts.sink,
    args = args,
  })
end

--------------------------------------------------------------------------------
-- Fzf     | https://github.com/junegunn/fzf
-- Fd      | https://github.com/sharkdp/fd
-- Ripgrep | https://github.com/BurntSushi/ripgrep
--------------------------------------------------------------------------------
T.find_files = function() util.fzf_cmd({ title = 'Files', cmd = 'files', sink = sink.edit_file }) end
T.git_files = function() util.fzf_cmd({ title = 'Git Files', cmd = 'git_files', sink = sink.edit_file }) end
T.grep = function() util.fzf_cmd({ title = 'Grep', cmd = 'grep', sink = sink.edit_or_sel_to_qf }) end
T.grep_global = function()
  local query = util.get_word_or_selection()
  local args = '--query=' .. vim.fn.shellescape(query)
  util.fzf_cmd({ title = 'Grep', cmd = 'grep', sink = sink.edit_or_sel_to_qf, args = args })
  util.extra_hl(query)
end
T.grep_note = function()
  local args = string.format('--query=%q --mode=%s', vim.fn.shellescape('\\b(TODO|FIXME|HACK|NOTE)\\b'), 'regex')
  util.fzf_cmd({ title = 'Grep', cmd = 'grep', sink = sink.edit_or_sel_to_qf, args = args })
end
T.grep_buffer = function()
  local query = util.get_word_or_selection()
  local line = unpack(vim.api.nvim_win_get_cursor(0))
  local current_file = vim.api.nvim_buf_get_name(0)
  local args = string.format('--query=%s --path=%s --line=%d', vim.fn.shellescape(query), current_file, line)
  util.fzf_cmd({
    title = 'Grep Buffer',
    cmd = 'grep_buffer',
    sink = sink.go_to_line,
    args = args,
  })
  util.extra_hl(query)
end

--------------------------------------------------------------------------------
-- NNN | https://github.com/jarun/nnn/wiki/Usage#from-source
-- Change default map l to open file (like <CR>)
--------------------------------------------------------------------------------

T.explorer = function() util.nnn_cmd({ title = 'NNN', sink = sink.edit_file }) end

-- Disable netrw
local disabled_built_ins = {
  'netrw',
  'netrwPlugin',
  'netrwSettings',
  'netrwFileHandlers',
}

for _, plugin in pairs(disabled_built_ins) do
  vim.g['loaded_' .. plugin] = 1
end

pcall(vim.api.nvim_clear_autocmds, { group = 'FileExplorer' })

vim.api.nvim_create_autocmd({ 'BufEnter', 'BufNewFile' }, {
  callback = function(args)
    local path = args.file
    if vim.fn.isdirectory(path) == 1 then
      local buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end
      vim.schedule(function() util.nnn_cmd({ title = 'NNN', path = path, sink = sink.edit_file }) end)
    end
  end,
})

-- Autocmd update file ---------------------------------------------------------
vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  desc = 'recent_file: add file',
  callback = function(ctx)
    if util.is_root() then return end

    local file = vim.uv.fs_realpath(ctx.file or '')
    if not file or vim.fn.isdirectory(file) == 1 then return end

    vim.system({ 'fz', 'add_recent_file', file }, { text = true }, function(obj)
      if obj.code ~= 0 then print('Error: ' .. obj.stderr) end
    end)
  end,
})

-- Autoinsert terminal mode ----------------------------------------------------
vim.api.nvim_create_autocmd({ 'TermOpen', 'WinEnter' }, {
  pattern = 'term://*',
  callback = vim.schedule_wrap(function(data)
    -- Try to start terminal mode only if target terminal is current
    if not (vim.api.nvim_get_current_buf() == data.buf and vim.bo.buftype == 'terminal') then return end
    vim.cmd('startinsert')
  end),
  desc = 'auto insert current terminal',
})

-- Cmd helper ------------------------------------------------------------------
-- Helper to run a shell or vim command and open result in scratch window
local function run_and_open(cmd, fn)
  if cmd and cmd ~= '' then
    vim.cmd('noswapfile vnew')
    vim.bo.buftype = 'nofile'
    vim.bo.bufhidden = 'wipe'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, fn(cmd))
  end
end

-- Prompt to run a shell command, open result
function T.run_shell()
  local cmd = vim.fn.input({ prompt = 'Run shell> ', completion = 'shellcmd' })
  if cmd and cmd ~= '' then run_and_open(cmd, vim.fn.systemlist) end
end

-- Prompt to run a vim command, open result
function T.run_vim()
  local cmd = vim.fn.input({ prompt = 'Vim command> ', completion = 'command' })
  if cmd and cmd ~= '' then
    cmd = string.format('lua P(%s)', cmd)
    run_and_open(cmd, function(c) return vim.split(vim.fn.execute(c), '\n') end)
  end
end

-- Toggle Terminal -------------------------------------------------------------
T.term = {}
util.term = {}

-- Kill terminal instance
function util.term.term_close(opts)
  local id, mode = opts.id, opts.mode
  if not T.term[id] then return end

  util.win_close(T.term[id].win_id)

  if mode ~= nil then
    util.win_focus(T.term[id].prev_win_id)
    T.term[id].win_id, T.term[id].prev_win_id = nil, nil
    if mode == 'kill' then
      util.buf_delete(T.term[id].buf_id)
      T.term[id] = nil
    end
  end
end

-- Hide all terminal drawers in current tab
function util.term.close_drawer_opened(win_id)
  local tabnr = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if #T.term > 0 then
      for id, term in ipairs(T.term) do
        if term.win_id == win.winid then util.term.term_close({ id = id }) end
      end
    end
    if win.tabnr == tabnr and win.winid ~= win_id and win.variables.drawer ~= nil then util.win_close(win.winid) end
  end
end

-- Toggle terminal window
function util.term.toggle_term(opts)
  local cmd = opts.cmd or vim.o.shell
  local t = T.term[opts.id] or {}

  -- If already open, close it
  if util.valid_win(t.win_id) then
    util.term.term_close({ id = opts.id, mode = 'close' })
    return
  end

  util.term.close_drawer_opened(t.win_id)

  vim.defer_fn(function()
    local cwd = opts.cwd or vim.uv.cwd()
    if opts.buffer then cwd = vim.fn.expand('%:p:h') end
    local win_opts = {
      split = 'below',
      height = 10,
      win = -1,
    }

    local win = util.win_open(opts.win or win_opts, t.buf_id)

    local win_id, buf_id, prev_win_id = win.win_id, win.buf_id, win.prev_win_id
    vim.bo.buflisted = false
    vim.wo.signcolumn = 'no'
    vim.api.nvim_win_set_var(win_id, 'drawer', true)

    local function kill() util.term.term_close({ id = opts.id, mode = 'kill' }) end

    vim.keymap.set('t', '<C-q>', kill, { buffer = win.buf_id })

    -- If already has terminal buffer, attach it
    if t.buf_id and vim.api.nvim_buf_is_valid(t.buf_id) then
      vim.api.nvim_win_set_buf(win_id, t.buf_id)
      T.term[opts.id].win_id = win_id
      T.term[opts.id].prev_win_id = prev_win_id
    else
      local job_opts = opts.job or {
        term = true,
        cwd = cwd,
      }
      job_opts.on_exit = function()
        -- vim.schedule(function() util.term.term_close({ id = opts.id, mode = 'kill' }) end)
      end
      -- Start new terminal job_id
      local job_id = vim.fn.jobstart(cmd, job_opts)

      T.term[opts.id] = { buf_id = buf_id, win_id = win_id, job_id = job_id, prev_win_id = prev_win_id }
    end
  end, 50)
end

function T.term_1() util.term.toggle_term({ id = 1 }) end
function T.term_2() util.term.toggle_term({ id = 2 }) end
function T.term_3() util.term.toggle_term({ id = 3, buffer = true }) end

--------------------------------------------------------------------------------
-- Gitui | https://github.com/gitui-org/gitui/releases/download/v0.27.0/gitui-linux-x86_64.tar.gz
--------------------------------------------------------------------------------
do
  local editor_script = os.getenv('HOME') .. '/.local/bin/nvim-server.sh'

  if vim.fn.filereadable(editor_script) == 0 then
    local f = io.open(editor_script, 'w')
    if not f then return end
    f:write('#!/bin/bash\n')
    f:write('nvim --server "$Nvim" --remote "$1"\n')
    f:close()
    vim.fn.system({ 'chmod', '+x', editor_script })
  end

  function T.gitui()
    vim.cmd('tabedit')
    vim.cmd('setlocal nonumber signcolumn=no')

    vim.fn.jobstart('gitui', {
      term = true,
      env = {
        GIT_EDITOR = editor_script,
      },
      on_exit = function()
        vim.cmd('silent! checktime')
        vim.cmd('silent! bw')
      end,
    })
  end
  -- function T.gitui()
  --   util.term.toggle_term({
  --     id = 4,
  --     cmd = 'gitui',
  --     win = {
  --       split = 'below',
  --       height = vim.o.lines,
  --       win = -1,
  --     },
  --     job = {
  --       term = true,
  --       env = {
  --         GIT_EDITOR = editor_script,
  --       },
  --     },
  --   })
  -- end
end

-- Quickfix --------------------------------------------------------------------
function T.open_win_qf(type)
  return function()
    local wininfo = vim.fn.getwininfo()
    for _, win in ipairs(wininfo) do
      if win.variables.drawer ~= nil then vim.api.nvim_win_hide(win.winid) end
    end
    if type == 'l' then
      -- open all non-empty loclists
      for _, win in ipairs(wininfo) do
        if win.quickfix == 0 then
          if not vim.tbl_isempty(vim.fn.getloclist(win.winnr)) then
            vim.api.nvim_set_current_win(win.winid)
            vim.cmd('lopen')
          else
            vim.notify('loclist is empty.', vim.log.levels.WARN)
          end
          return
        end
      end
    else
      -- open quickfix if not empty
      if not vim.tbl_isempty(vim.fn.getqflist()) then
        vim.cmd('copen')
        vim.g.win_qf = vim.api.nvim_get_current_win()
      else
        vim.notify('quickfix is empty.', vim.log.levels.WARN)
      end
    end
  end
end

do
  local function escape_pattern(str) return str:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1') end

  local function qf_replace_prompt()
    local pattern = vim.fn.input('Search pattern: ')
    if pattern == '' then
      vim.notify('qfreplace: pattern kosong.', vim.log.levels.WARN)
      return
    end

    local replacement = vim.fn.input('Replace with: ')

    local qflist = vim.fn.getqflist()
    local count = 0
    local prev_bufnr = -1
    local qf_was_open = false
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'qf' then
        qf_was_open = true
        vim.cmd('cclose')
        break
      end
    end
    local buf = vim.api.nvim_create_buf(false, true) -- [listed=false, scratch=true]
    local win = vim.api.nvim_open_win(buf, true, {
      split = 'below',
      win = -1,
    })

    vim.bo[buf].bufhidden = 'wipe'
    vim.bo[buf].buftype = 'nofile'
    vim.bo[buf].swapfile = false
    vim.bo[buf].modifiable = false
    vim.bo[buf].readonly = true

    for _, e in ipairs(qflist) do
      if e.bufnr and e.bufnr ~= 0 and e.lnum then
        if prev_bufnr ~= e.bufnr then
          vim.cmd('buffer ' .. e.bufnr)
          prev_bufnr = e.bufnr
        end

        -- local line = vim.fn.getline(e.lnum)
        local line = vim.api.nvim_buf_get_lines(e.bufnr, e.lnum - 1, e.lnum, true)[1]
        local new_line, n = line:gsub(escape_pattern(pattern), replacement)
        if n > 0 and line ~= new_line then
          -- vim.fn.setline(e.lnum, new_line)
          vim.api.nvim_buf_set_lines(0, e.lnum - 1, e.lnum, true, { new_line }) -- use vim.api

          count = count + 1
        end
      end
    end

    vim.cmd('update')

    if vim.api.nvim_win_is_valid(win) then pcall(vim.api.nvim_win_close, win, true) end
    if vim.api.nvim_buf_is_valid(buf) then vim.api.nvim_buf_delete(buf, { force = true }) end

    local new_qflist = vim.deepcopy(qflist)
    for _, e in ipairs(new_qflist) do
      if e.bufnr and e.bufnr ~= 0 and e.lnum then
        local line = vim.api.nvim_buf_get_lines(e.bufnr, e.lnum - 1, e.lnum, true)[1] -- use vim.api
        -- local line = vim.fn.getbufline(e.bufnr, e.lnum)[1]
        if type(line) == 'string' then e.text = line end
      end
    end
    vim.fn.setqflist(new_qflist, 'r')

    if qf_was_open then vim.cmd('copen') end
    vim.notify(string.format('qfreplace: %d replacement(s) done.', count), vim.log.levels.INFO)
  end

  vim.api.nvim_create_user_command('QFreplace', function() qf_replace_prompt() end, {})

  -- Setup autocmd
  vim.api.nvim_create_autocmd('FileType', {
    pattern = 'qf',
    desc = 'FileType qf',
    callback = function(ctx)
      vim.api.nvim_win_set_var(vim.api.nvim_get_current_win(), 'drawer', true)
      vim.keymap.set('n', 'r', '<Cmd>QFreplace<CR>', { buffer = ctx.buf, nowait = true })
    end,
  })
end

-- Setup keymap ----------------------------------------------------------------
util.setup()

return T
--------------------------------------------------------------------------------
