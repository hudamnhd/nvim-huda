--------------------------------------------------------------------------------
--- Usercmds
--------------------------------------------------------------------------------
local M = {}

-- remove all buffers except the current one
M.buf_clean = function()
  local cur = vim.api.nvim_get_current_buf()

  local deleted, modified = 0, 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_get_option_value('modified', { buf = buf }) then
      modified = modified + 1
    elseif buf ~= cur and vim.api.nvim_get_option_value('modifiable', { buf = buf }) then
      vim.api.nvim_buf_delete(buf, { force = true })
      deleted = deleted + 1
    end
  end

  vim.notify(('%s deleted, %s modified'):format(deleted, modified), vim.log.levels.WARN, {})
end

-- Scratch buffer
M.buf_scratch = function()
  vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, { split = 'below', height = 20 })
end

-- diff toggle
M.win_diff_toggle = function()
  if vim.wo.diff then
    vim.cmd('windo diffoff')
  else
    vim.cmd('windo diffthis')
    vim.cmd('windo set wrap')
  end
end

-- Toggle line number
do
  local LINE_NUMBERS = {
    ff = '  nu   rnu',
    ft = '  nu nornu',
    tf = 'nonu nornu',
    tt = '  nu nornu',
  }
  function M.toggle_line_numbers()
    local n = vim.o.number and 't' or 'f'
    local r = vim.o.relativenumber and 't' or 'f'
    local cmd = LINE_NUMBERS[n .. r]
    vim.api.nvim_command('set ' .. cmd)
    print(cmd)
  end
end

-- Set cwd ---------------------------------------------------------------------
function M.smart_cd()
  local file_dir = vim.fn.expand('%:h')
  vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true, cwd = file_dir }, function(result)
    if result.code == 0 and result.stdout then
      local git_root = result.stdout:gsub('%s+$', '')
      vim.schedule(function()
        vim.cmd('cd ' .. vim.fn.fnameescape(git_root))
        vim.notify(('Working directory set to Git root: %s'):format(git_root), vim.log.levels.INFO, {})
      end)
    else
      vim.schedule(function()
        vim.cmd('cd ' .. vim.fn.fnameescape(file_dir))
        vim.notify(('Git root not found. Using current file dir: %s'):format(file_dir), vim.log.levels.WARN, {})
      end)
    end
  end)
end

vim.api.nvim_create_user_command("My", function(opts)
  local subcmd = opts.fargs[1]

  if subcmd then
    if M[subcmd] and type(M[subcmd]) == "function" then
      M[subcmd]()
    else
      print("Unknown command: " .. subcmd)
    end
    return
  end

  local keys = {}
  for k, v in pairs(M) do
    if type(v) == "function" then
      table.insert(keys, k)
    end
  end
  table.sort(keys)

  vim.ui.select(keys, { prompt = "My command:" }, function(choice)
    if choice then
      M[choice]()
    else
      print("Canceled")
    end
  end)
end, {
  nargs = "?",
  complete = function(ArgLead, CmdLine, CursorPos)
    local keys = {}
    for k, v in pairs(M) do
      if type(v) == "function" and k:match("^" .. ArgLead) then
        table.insert(keys, k)
      end
    end
    return keys
  end,
})

return M
--------------------------------------------------------------------------------
