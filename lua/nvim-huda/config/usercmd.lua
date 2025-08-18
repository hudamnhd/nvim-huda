--------------------------------------------------------------------------------
--- Usercmds
--------------------------------------------------------------------------------

-- remove all buffers except the current one
vim.api.nvim_create_user_command('BufClean', function()
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
end, {
  desc = 'Remove all buffers except the current one.',
})

-- Scratch buffer
vim.api.nvim_create_user_command(
  'Scratch',
  function() vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), true, { split = 'below', height = 20 }) end,
  {
    desc = 'New scratch buffer',
  }
)

-- diff toggle
vim.api.nvim_create_user_command('Difftoggle', function()
  if vim.wo.diff then
    vim.cmd('windo diffoff')
  else
    vim.cmd('windo diffthis')
    vim.cmd('windo set wrap')
  end
end, {
  desc = 'Toggle diff',
})

vim.api.nvim_create_user_command("PrintHighlights", function()
  vim.cmd "redir! > highlights.txt | silent hi | redir END"
end, {})

vim.api.nvim_create_user_command("PrintRemaps", function()
  vim.cmd "redir! > remaps.txt | silent map | redir END"
end, {})
--------------------------------------------------------------------------------
