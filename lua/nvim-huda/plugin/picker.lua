local SCRIPTS_DIR = _my.PLUGIN_DIR .. '/script'

local FZ = SCRIPTS_DIR .. '/fz'

-- Make sure it's executable
if vim.fn.executable(FZ) == 0 then
  os.execute('chmod +x ' .. vim.fn.shellescape(FZ))
  print('Run: chmod +x ' .. FZ)
end

local T, sink = {}, {}
local util = require('nvim-huda.util')
local TEMPNAME = vim.fn.tempname()

if vim.fn.executable('nnn') == 0 and vim.fn.executable('fzf') == 0 then return end

-- Keymap  --------------------------------------------------------------------
function util.setup()
  map('n', '<Leader>e', T.file_explorer, { desc = 'Open directory current file' })

  map('n', '<Leader>f', T.find_files, { desc = 'Open file picker at cwd' })
  map('n', '<Leader>F', T.git_files, { desc = 'Open file picker at git root' })

  map('n', '<Leader>/', T.grep, { desc = 'Search in workspace folder' })
  map('nx', '<Leader>*', T.grep_global, { desc = 'Search word/selection in workspace folder' })

  map('n', 'g/', T.bgrep, { desc = 'Search in current file' })
  map('nx', 'g*', T.grep_buffer, { desc = 'Search word/selection in current file' })

  map('n', '<Leader>!', T.grep_note, { desc = 'Search highlight text "NOTE/FIXME/TODO/HACK"' })
  map('n', '<Leader>#', T.find_bookmark_dir, { desc = 'Open bookmark directory ~/.bookmarks' })

  map('n', '<Leader>xs', T.run_shell, { desc = 'Run and open result shell cmd' })
  map('n', '<Leader>xv', T.run_vim, { desc = 'Run and open result vim cmd' })
end

-- Sink ------------------------------------------------------------------------
function sink.edit_file(selected, opts)
  local cwd = vim.uv.cwd()
  for i, sel in ipairs(selected) do
    if cwd ~= opts.cwd then sel = vim.fs.joinpath(opts.cwd, sel) end
    if vim.fn.isdirectory(sel) == 1 then
      if i == #selected then vim.cmd('edit ' .. vim.fn.fnameescape(sel)) end
    elseif vim.fn.filereadable(sel) == 1 then
      vim.cmd('edit ' .. vim.fn.fnameescape(sel))
    else
      vim.system({ FZ, 'remove_recent_file', sel }, { text = true }, function(obj)
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
function util.get_query_arg(opts)
  for _, arg in ipairs(opts.args or {}) do
    local query = arg:match('%-%-query=[\'"](.-)[\'"]')
    if query then return query end
  end
  return nil
end

function util.jobstart(opts)
  local win = util.win_open(opts.win)
  local query = util.get_query_arg(opts)

  if opts.on_enter then opts.on_enter() end

  local cwd = vim.uv.cwd()
  vim.bo[win.buf_id].bufhidden = 'wipe'
  vim.bo[win.buf_id].buftype = 'nofile'

  local function callback()
    vim.defer_fn(function()
      if vim.fn.filereadable(TEMPNAME) == 1 then opts.sink(vim.fn.readfile(TEMPNAME), { query = query, cwd = cwd }) end
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
    on_enter = opts.on_enter,
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
local default_find_files = {
  title = 'Files',
  cmd = 'files',
  sink = sink.edit_file,
}

vim.api.nvim_create_user_command('F', function(info)
  -- local cwd = info.fargs[1] and vim.fn.fnamemodify(info.fargs[1], ':p') or vim.uv.cwd()
  local cwd = info.fargs[1] or vim.uv.cwd()
  util.fzf_cmd(vim.tbl_deep_extend('force', default_find_files, { on_enter = function() vim.cmd('lcd ' .. cwd) end }))
end, { nargs = '?', complete = 'dir', desc = 'Fuzzy find files.' })

vim.api.nvim_create_user_command(
  'G',
  function(info) util.fzf_cmd({ title = 'Grep', cmd = 'grep', sink = sink.edit_or_sel_to_qf }) end,
  { nargs = '?', desc = 'Grep' }
)

T.find_bookmark_dir = function()
  util.fzf_cmd({
    title = 'Directory',
    cmd = 'files',
    args = '--cmd="cat ~/.bookmarks"',
    sink = function(selected) vim.cmd('F ' .. selected[1]) end,
  })
end

T.find_files = function() util.fzf_cmd(vim.tbl_deep_extend('force', default_find_files, { cmd = 'smart_files' })) end
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
  local word = vim.fn.mode() == 'n' and ' --word=' .. query or ''
  local args = string.format('--query=%s --path=%s --line=%d%s', vim.fn.shellescape(query), current_file, line, word)
  util.fzf_cmd({
    title = 'Grep Buffer',
    cmd = 'grep_buffer',
    sink = sink.go_to_line,
    args = args,
  })
  util.extra_hl(query)
end
T.bgrep = function()
  local query = ''
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

T.file_explorer = function() util.nnn_cmd({ title = 'NNN', sink = sink.edit_file }) end

vim.api.nvim_create_user_command('E', function(info)
  local cwd = info.fargs[1] or vim.uv.cwd()
  util.nnn_cmd({ title = 'NNN', path = cwd, sink = sink.edit_file })
end, { nargs = '?', complete = 'dir', desc = 'File Explorer' })

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

    vim.system({ FZ, 'add_recent_file', file }, { text = true }, function(obj)
      if obj.code ~= 0 then print('Error: ' .. obj.stderr) end
    end)
  end,
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

-- Setup keymap ----------------------------------------------------------------
util.setup()

return T
--------------------------------------------------------------------------------
