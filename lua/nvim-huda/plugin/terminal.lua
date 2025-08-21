-- Toggle Terminal -------------------------------------------------------------
local T = {}
T.term = {}
local util = require('nvim-huda.util')

-- Autoinsert terminal mode ----------------------------------------------------
vim.api.nvim_create_autocmd({ 'TermOpen', 'WinEnter' }, {
  pattern = 'term://*',
  callback = vim.schedule_wrap(function(ctx)
    -- Try to start terminal mode only if target terminal is current
    if not (vim.api.nvim_get_current_buf() == ctx.buf and vim.bo.buftype == 'terminal') then return end
    vim.cmd('startinsert')
  end),
  desc = 'auto insert current terminal',
})

-- Kill terminal instance
function util.term_close(opts)
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
function util.close_drawer_opened(win_id)
  local tabnr = vim.api.nvim_get_current_tabpage()
  for _, win in ipairs(vim.fn.getwininfo()) do
    if #T.term > 0 then
      for id, term in ipairs(T.term) do
        if term.win_id == win.winid then util.term_close({ id = id }) end
      end
    end
    if win.tabnr == tabnr and win.winid ~= win_id and win.variables.drawer ~= nil then util.win_close(win.winid) end
  end
end

-- Toggle terminal window
function util.toggle_term(opts)
  local cmd = opts.cmd or vim.o.shell
  local t = T.term[opts.id] or {}

  -- If already open, close it
  if util.valid_win(t.win_id) then
    util.term_close({ id = opts.id, mode = 'close' })
    return
  end

  util.close_drawer_opened(t.win_id)

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
    vim.api.nvim_win_set_var(win_id, 'drawer', true)

    local function kill() util.term_close({ id = opts.id, mode = 'kill' }) end

    map('t', '<C-q>', kill, { buffer = win.buf_id })

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
      job_opts.on_exit = function(x,a)
        vim.schedule(function() util.term_close({ id = opts.id, mode = 'kill' }) end)
      end
      -- Start new terminal job_id
      local job_id = vim.fn.jobstart(cmd, job_opts)

      T.term[opts.id] = { buf_id = buf_id, win_id = win_id, job_id = job_id, prev_win_id = prev_win_id }
    end
  end, 50)
end

function T.term_1() util.toggle_term({ id = 1 }) end
function T.term_2() util.toggle_term({ id = 2, buffer = true }) end

--------------------------------------------------------------------------------
-- Gitui | https://github.com/gitui-org/gitui/releases/download/v0.27.0/gitui-linux-x86_64.tar.gz
--------------------------------------------------------------------------------
do
  if vim.fn.executable('gitui') == 0 then return end
  local editor_script = os.getenv('HOME') .. '/.local/bin/nvim-server.sh'

  if vim.fn.filereadable(editor_script) == 0 then
    local f = io.open(editor_script, 'w')
    if not f then return end
    f:write('#!/bin/bash\n')
    f:write('nvim --server "$NVIM" --remote-tab "$1"\n')
    f:close()
    vim.fn.system({ 'chmod', '+x', editor_script })
  end

  -- function T.open_gitui()
  --   vim.cmd('tabedit')
  --   vim.cmd('setlocal nonumber signcolumn=no')
  --
  --   vim.fn.jobstart('gitui', {
  --     term = true,
  --     env = {
  --       GIT_EDITOR = editor_script,
  --     },
  --     on_exit = function()
  --       vim.cmd('silent! checktime')
  --       vim.cmd('silent! bw')
  --     end,
  --   })
  -- end

  function T.open_gitui()
    util.toggle_term({
      id = 4,
      cmd = 'gitui',
      win = {
        split = 'below',
        height = vim.o.lines,
        win = -1,
      },
      job = {
        term = true,
        env = {
          GIT_EDITOR = editor_script,
        },
      },
    })
  end
  map({ 'n', 't' }, '<A-g>', T.open_gitui, { desc = 'Open gitui' })
end

map({ 'n', 't' }, '<A-`>', T.term_1, { desc = 'term 1' })
map({ 'n', 't' }, '<A-BS>', T.term_2, { desc = 'term 2 (local)' })

return T
