--------------------------------------------------------------------------------
-- Tabline
--------------------------------------------------------------------------------
local tabline = {}
tabline.buffer_state = {}
tabline.namespace = vim.api.nvim_create_namespace('tabline')

function tabline.relpath(path)
  local cwd = vim.uv.cwd()
  ---@diagnostic disable-next-line: need-check-nil
  local safe_cwd = cwd:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
  return (path:gsub('^' .. safe_cwd .. '/', ''))
end

function tabline.get_current_index()
  local current_buf = vim.api.nvim_get_current_buf()
  local buffer_state = tabline.buffer_state

  for i, entry in ipairs(buffer_state) do
    if entry.idbuf == current_buf then return i end
  end

  return nil
end

---@param opts vim.api.keyset.win_config
---@return { win_id: integer, buf_id: integer, prev_win_id: integer, close_win: fun() }
function tabline.win_open(opts)
  local prev_win_id = vim.api.nvim_get_current_win()
  local buf_id = vim.api.nvim_create_buf(false, true)

  vim.bo[buf_id].bufhidden = 'wipe'
  vim.bo[buf_id].buftype = 'nofile'

  local columns = vim.o.columns
  local lines = vim.o.lines
  local width = math.floor(columns * 0.9)
  local height = math.floor(lines * 0.59)
  local default_opts = {
    relative = 'editor',
    style = 'minimal',
    row = math.floor((lines - height) * 0.5),
    col = math.floor((columns - width) * 0.5),
    width = width,
    height = height,
    border = 'single',
    title = '',
    title_pos = 'center',
  }

  local win_opts = vim.tbl_deep_extend('force', default_opts, opts or {})
  local win_id = vim.api.nvim_open_win(buf_id, true, win_opts)
  local close_win = function()
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

-- Open buffer listed ----------------------------------------------------------
function tabline.open_buffer_list()
  if #tabline.buffer_state == 0 then
    vim.notify('bufferlist is empty.', vim.log.levels.WARN)
    return
  end

  local current_path = tabline.relpath(vim.api.nvim_buf_get_name(0))
  local win = tabline.win_open({ title = 'Buffer' })

  vim.wo[win.win_id].number = true
  vim.api.nvim_set_option_value('buftype', 'nofile', { buf = win.buf_id })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = win.buf_id })
  vim.api.nvim_set_option_value('swapfile', false, { buf = win.buf_id })
  vim.api.nvim_buf_set_name(win.buf_id, 'buffer')
  vim.api.nvim_set_current_buf(win.buf_id)

  local lines = {}
  for _, entry in ipairs(tabline.buffer_state) do
    table.insert(lines, entry.path)
  end
  vim.api.nvim_buf_set_lines(win.buf_id, 0, -1, false, lines)

  local target_line = 1
  for idx, entry in ipairs(tabline.buffer_state) do
    if entry.path == current_path then
      target_line = idx
      break
    end
  end

  vim.api.nvim_win_set_cursor(win.win_id, { target_line, 0 })

  for i, line in ipairs(lines) do
    local fname_start = line:find('[^/]+$') or 1
    local fname_end = #line
    if fname_start > 1 then
      vim.api.nvim_buf_set_extmark(win.buf_id, tabline.namespace, i - 1, 0, {
        end_col = fname_start - 1,
        hl_group = 'Comment',
      })
    end
    vim.api.nvim_buf_set_extmark(win.buf_id, tabline.namespace, i - 1, fname_start - 1, {
      end_col = fname_end,
      hl_group = 'Title',
    })
  end

  -- Keymaps
  vim.keymap.set('n', 'q', win.close_win, { buffer = win.buf_id, nowait = true })

  local function enter(line_nr)
    if type(line_nr) ~= 'number' then return end
    local line = vim.api.nvim_buf_get_lines(0, line_nr - 1, line_nr, false)[1]
    if not line or line == '' then return end

    local target = nil
    for _, entry in ipairs(tabline.buffer_state) do
      if entry.path == line then
        target = entry
        break
      end
    end

    if not target or not vim.api.nvim_buf_is_valid(target.idbuf) then
      vim.notify('Invalid buffer for path: ' .. line, vim.log.levels.WARN)
      return
    end

    win.close_win()
    vim.schedule(function() vim.api.nvim_set_current_buf(target.idbuf) end)
  end

  local function buf_enter() enter(vim.api.nvim_win_get_cursor(0)[1]) end

  vim.keymap.set('n', '<CR>', buf_enter, { buffer = win.buf_id, desc = 'Open buffer under cursor' })
  vim.keymap.set('n', 'l', buf_enter, { buffer = win.buf_id, desc = 'Open buffer under cursor' })

  vim.keymap.set('n', '=', function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

    local old_paths = {}
    for _, entry in ipairs(tabline.buffer_state) do
      old_paths[entry.path] = entry.idbuf
    end

    local new_paths = {}
    local filtered = {}
    for _, file in ipairs(lines) do
      local bufnr = vim.fn.bufnr(file)
      local real = vim.loop.fs_realpath(file)
      local stat = real and vim.loop.fs_stat(real)
      if stat and stat.type == 'file' then
        if bufnr == -1 then
          vim.cmd('badd ' .. vim.fn.fnameescape(file))
          bufnr = vim.fn.bufnr(file)
        end
        table.insert(filtered, { idbuf = bufnr, path = file })
        new_paths[file] = true
      end
    end

    -- handle bufdelete otomatis
    for path, bufnr in pairs(old_paths) do
      if not new_paths[path] and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_delete(bufnr, { force = true })
      end
    end

    tabline.buffer_state = filtered
    vim.notify('Updated buffer list.')
  end, { buffer = win.buf_id })
  local ns_id = vim.api.nvim_create_namespace('BufferJump')

  for i, _ in ipairs(lines) do
    vim.api.nvim_buf_set_extmark(win.buf_id, ns_id, i - 1, 0, {
      number_hl_group = 'WarningMsg',
    })
  end
  -- tabline.handle_key(function(ch)
  --   vim.api.nvim_buf_clear_namespace(win.buf_id, ns_id, 0, -1)
  --   enter(tonumber(ch))
  -- end)
end

tabline.handle_key = function(callback)
  vim.defer_fn(function()
    local ok, ch = pcall(vim.fn.getchar)
    if not ok then return end
    local ch = type(ch) == 'number' and vim.fn.nr2char(ch) or ch
    callback(ch)
  end, 10)
end

tabline.buffer_seen = {}

function tabline.open_buf_with_click(bufnr) vim.api.nvim_set_current_buf(bufnr) end

-- Render tabline --------------------------------------------------------------
function tabline.render_buffer()
  local current = vim.fn.bufnr()
  local alternate = vim.fn.bufnr('#')
  local tab_count = vim.fn.tabpagenr('$')
  local tab_index = vim.fn.tabpagenr()

  local line = ''
  if tab_count > 1 then line = line .. '%#TabLineCount#' .. string.format('[Tab %d/%d] ', tab_index, tab_count) end

  -- pakai tabline.buffer_state sebagai sumber urutan
  for i, buf in ipairs(tabline.buffer_state) do
    local path = buf.path
    local bufnr = buf.idbuf
    if bufnr ~= -1 then
      local modified = vim.fn.getbufvar(bufnr, '&modified') == 1
      local is_current = (bufnr == current)
      local is_alt = (bufnr == alternate)

      local suffix = ''
      if modified then suffix = suffix .. '**' end
      if is_alt then suffix = suffix .. '#' end

      local hl = is_current and '%#TabLineSel#' or '%#TabLine#'
      local name = vim.fn.fnamemodify(path, ':t') or '[No Name]'
      local short_name = name
      tabline.buffer_seen[name] = (tabline.buffer_seen[name] or 0) + 1

      if tabline.buffer_seen[name] > 1 then
        local parent = vim.fn.fnamemodify(path, ':h:t')
        if parent == '' then parent = '...' end
        short_name = string.format('%s/%s', parent, name)
      end

      local label = string.format('%d %s%s', i, short_name, suffix)
      local click = string.format('%%%d@v:lua.open_buf_with_click@ ', bufnr)

      line = line .. hl .. click .. label .. ' ' .. '%X'
    end
  end

  return line .. '%#TabLineFill#'
end

-- Setup keymap, opt and autocmd -----------------------------------------------
tabline.setup = function()
  _G.open_buf_with_click = tabline.open_buf_with_click
  _G.render_buffer = tabline.render_buffer

  -- show bufferline via tabline
  vim.o.showtabline = 2
  vim.o.tabline = '%!v:lua.render_buffer()'

  vim.keymap.set('n', '<Leader>b', tabline.open_buffer_list, { desc = 'Buffer list' })

  function next_state()
    local count = vim.v.count1
    local buffer_state = tabline.buffer_state
    local index = tabline.get_current_index()

    if not index then
      print('Current buffer not found in buffer_state')
      return
    end

    local next_index = ((index - 1 + count) % #buffer_state) + 1
    local target = buffer_state[next_index]
    if type(target) == 'table' then vim.api.nvim_set_current_buf(target.idbuf) end
  end

  function prev_state()
    local count = vim.v.count1
    local buffer_state = tabline.buffer_state
    local index = tabline.get_current_index()

    if not index then
      print('Current buffer not found in buffer_state')
      return
    end

    local prev_index = ((index - 1 - count + #buffer_state) % #buffer_state) + 1
    local target = buffer_state[prev_index]
    if type(target) == 'table' then vim.api.nvim_set_current_buf(target.idbuf) end
  end

  vim.keymap.set('n', '<Tab>', next_state)
  vim.keymap.set('n', '<S-Tab>', prev_state)

  -- Leader + number(1-9) for navigate bufferline
  local keys = '123456789'
  for i = 1, #keys do
    local key = keys:sub(i, i)
    local key_combination = string.format('<Leader>%s', key)
    vim.keymap.set('n', key_combination, function()
      local target = tabline.buffer_state[i]
      if type(target) == 'table' then
        vim.api.nvim_set_current_buf(target.idbuf)
      else
        vim.notify('Buffer #' .. i .. ' not found', vim.log.levels.WARN)
      end
    end, { desc = 'Goto buffer ' .. i })
  end

  -- sinkron tabline.buffer_state
  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    callback = function(args)
      local bufnr = args.buf
      if vim.fn.isdirectory(args.file) == 1 then return end
      -- filter tabline.buffer_state, hapus jika idbuf sudah tidak valid
      local new_blines = {}
      for _, entry in ipairs(tabline.buffer_state) do
        if entry.idbuf ~= bufnr then table.insert(new_blines, entry) end
      end
      tabline.buffer_state = new_blines
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufEnter', 'BufNewFile' }, {
    callback = function(args)
      if vim.fn.isdirectory(args.file) == 1 then return end
      local known = {}
      for _, entry in ipairs(tabline.buffer_state) do
        known[entry.path] = true
      end

      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bufnr].buflisted then
          local name = vim.api.nvim_buf_get_name(bufnr)
          local path = tabline.relpath(name)
          if path ~= '' and not known[path] then table.insert(tabline.buffer_state, { idbuf = bufnr, path = path }) end
        end
      end
    end,
  })
end

--------------------------------------------------------------------------------
-- Statusline
--------------------------------------------------------------------------------
local statusline = {}

statusline.mode_alias = {
  n = 'Normal',
  niI = 'Normal',
  niR = 'Normal',
  niV = 'Normal',
  nt = 'Normal',
  v = 'Visual',
  V = 'V-Line',
  ['\x16'] = 'V-Block',
  i = 'Insert',
  ic = 'Insert',
  R = 'Replace',
  Rv = 'V-Replace',
  c = 'Command',
  s = 'Select',
  S = 'S-Line',
  ['\x13'] = 'S-Block',
  t = 'Terminal',
  cv = 'Ex',
  ce = 'Ex',
}

function _G.NH.sl_mode()
  local mode = vim.api.nvim_get_mode().mode
  local m = statusline.mode_alias[mode] or statusline.mode_alias[string.sub(mode, 1, 1)] or 'UNK'
  return m:sub(1, 3):upper()
end

local components = {
  ' %{v:lua.NH.sl_mode()}%*',
  ":%{(&modified&&&readonly?'%*':(&modified?'**':(&readonly?'%%':'--')))}",
  ' %P (%#StatusLineNr#%l%*,%02c) ',
  '%f',
  ' %=',
  '%y ',
  '%{&ff} ',
  '%{&fenc?&fenc:&enc} ',
  '(%L) ',
}

function NH.statusline() return table.concat(components) end

--------------------------------------------------------------------------------
-- Setup Tabline and Statusline
--------------------------------------------------------------------------------

vim.api.nvim_create_autocmd('UIEnter', {
  desc = 'Setup ui on UIEnter Event ',
  once = true,
  callback = vim.schedule_wrap(function()
    tabline.setup()
    vim.opt.statusline = '%{%v:lua._G.NH.statusline()%}'
    vim.api.nvim_set_hl(0, 'StatusLineNr', { fg = nil, bg = nil, bold = true })
  end),
})

--------------------------------------------------------------------------------
