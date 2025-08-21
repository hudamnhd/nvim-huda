local T = {}

vim.cmd('command! -nargs=+ -complete=file Grep noautocmd grep! <args> | redraw! | copen')
vim.cmd('command! -nargs=+ -complete=file LGrep noautocmd lgrep! <args> | redraw! | lopen')

-- Use ':Grep' or ':LGrep' to grep into quickfix|loclist
-- without output or jumping to first match
-- Use ':Grep <pattern> %' to search only current file
-- Use ':Grep <pattern> %:h' to search the current file dir

-- Global Search Replace Quickfix
-- * `:cdo` = "run every line in Quickfix"  | :cdo %s/foo/bar/g  | update
-- * `:cfdo` = "run every file in Quickfix" | :cfdo %s/foo/bar/g | update
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
    map('n', 'r', '<Cmd>QFreplace<CR>', { buffer = ctx.buf, nowait = true })
  end,
})

map('n', '<Leader>xq', T.open_win_qf('q'), { desc = 'Quickfix List' })
map('n', '<Leader>xl', T.open_win_qf('l'), { desc = 'Location List' })

return T
--------------------------------------------------------------------------------
