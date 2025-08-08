--------------------------------------------------------------------------------
--- Autocmd
--------------------------------------------------------------------------------
local group = vim.api.nvim_create_augroup('NHAugroup', { clear = true })

-- Wrapper autocmd
local function autocmd(event, opts)
  opts.group = opts.group or group
  vim.api.nvim_create_autocmd(event, opts)
end

autocmd({ 'TextYankPost' }, {
  desc = 'Highlighted yank',
  callback = function()
    vim.hl.on_yank({ timeout = 100 })
    if vim.v.event.operator == 'y' and vim.v.event.regname == '' and vim.b.cursor_pre_yank then
      vim.api.nvim_win_set_cursor(0, vim.b.cursor_pre_yank)
      vim.b.cursor_pre_yank = nil
    end
  end,
})

-- https://github.com/mhinz/vim-galore?tab=readme-ov-file#restore-cursor-position-when-opening-file
autocmd({ 'FileType' }, {
  desc = 'Restore cursor position',
  callback = function(ctx)
    if vim.bo[ctx.buf].buftype ~= '' then return end
    vim.cmd([[silent! normal! g`"]])
  end,
})

autocmd({ 'BufWritePre' }, {
  desc = 'Auto create dir when saving a file, in case some intermediate directory does not exist',
  callback = function(event)
    if event.match:match('^%w%w+:[\\/][\\/]') then return end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
  end,
})

autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
  desc = 'Check if we need to reload the file when it changed',
  callback = function()
    if vim.o.buftype ~= 'nofile' then vim.cmd('checktime') end
  end,
})

autocmd({ 'BufLeave', 'WinLeave', 'FocusLost' }, {
  desc = 'Autosave on focus change',
  nested = true,
  callback = function(info)
    -- Don't auto-save non-file buffers
    if (vim.uv.fs_stat(info.file) or {}).type ~= 'file' then return end
    vim.cmd.update({
      mods = { emsg_silent = true },
    })
  end,
})

autocmd({ 'BufWritePre' }, {
  desc = 'Delete trailing whitespace',
  pattern = '*',
  callback = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd(':%s/\\s\\+$//e')
    vim.api.nvim_win_set_cursor(0, pos)
  end,
})

autocmd({ 'FileType', 'CmdwinEnter' }, {
  pattern = { '/', 'vim', 'qf', 'man', 'help', 'checkhealth', 'qfreplace' },
  desc = 'Close special buffers with <q>',
  callback = function(event)
    local buf = event.buf
    local ft = event.match
    local bt = vim.bo[buf].buftype

    if ft == 'vim' and bt ~= 'nofile' then return end
    if ft == '/' and bt ~= 'nofile' then return end

    vim.bo[buf].buflisted = false
    vim.keymap.set('n', 'q', function()
      vim.cmd('close')
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end, {
      buffer = buf,
      silent = true,
      nowait = true,
      desc = 'Quit buffer',
    })
  end,
})

--------------------------------------------------------------------------------
