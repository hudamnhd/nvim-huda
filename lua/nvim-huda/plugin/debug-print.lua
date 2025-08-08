local M = {}

M.format = {
  lua = function(word, meta)
    return string.format(
      "print('DEBUG[%d]: %s:%d: %s=' .. vim.inspect(%s))",
      meta.id,
      meta.filename,
      meta.linenr,
      word,
      word
    )
  end,

  vim = function(word, meta)
    return string.format("echom 'DEBUG[%d]: %s:%d: %s=' . string(%s)", meta.id, meta.filename, meta.linenr, word, word)
  end,

  javascript = function(word, meta)
    return string.format("console.log('DEBUG[%d]: %s:%d: %s=', %s);", meta.id, meta.filename, meta.linenr, word, word)
  end,

  typescript = function(...) return M.format.javascript(...) end,
  javascriptreact = function(...) return M.format.javascript(...) end,
  typescriptreact = function(...) return M.format.javascript(...) end,

  go = function(word, meta)
    return string.format('fmt.Println("DEBUG[%d]: %s:%d: %s=", %s)', meta.id, meta.filename, meta.linenr, word, word)
  end,
}

function M.insert_debugprint(word)
  if word == '' then
    vim.notify('No word under cursor', vim.log.levels.WARN)
    return
  end

  local ft = vim.bo.filetype
  local formatter = M.format[ft]
  if not formatter then
    vim.notify('No debug formatter for filetype: ' .. ft, vim.log.levels.ERROR)
    return
  end

  local linenr = vim.fn.line('.')
  local filename = vim.fn.expand('%:t')
  local rand = math.random(100, 999)

  local meta = {
    id = rand,
    filename = filename,
    linenr = linenr,
  }

  local debug_line = formatter(word, meta)

  -- get indent prev line
  local prev_line = vim.api.nvim_buf_get_lines(0, linenr - 1, linenr, false)[1] or ''
  local indent = prev_line:match('^%s*') or ''

  -- add indent in front debugline
  debug_line = indent .. debug_line
  vim.api.nvim_buf_set_lines(0, linenr, linenr, false, { debug_line })
end

function M.setup()
  vim.keymap.set(
    'n',
    '<Leader>cw',
    function() M.insert_debugprint(vim.fn.expand('<cword>')) end,
    { desc = 'Code word debug print' }
  )
end

M.setup()

return M

--------------------------------------------------------------------------------
