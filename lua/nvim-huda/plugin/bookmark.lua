--------------------------------------------------------------------------------
-- Bookmark
--------------------------------------------------------------------------------
-- local MAX_FILES = 100
local bookmark = {}
local util = {}
local json_path = vim.fn.stdpath('state') .. '/bookmarks.json'

--- Returns unique project ID based on git root + branch or cwd fallback
---@return string
function util.get_map_id()
  local branch = vim.fn.system('git rev-parse --abbrev-ref HEAD')
  if vim.v.shell_error == 0 then
    local git_root = vim.fn.system('git rev-parse --show-toplevel'):gsub('%s+$', '')
    return git_root .. ':' .. branch:gsub('%s+$', '')
  end
  return vim.fn.getcwd()
end

-- Helpers
function util.split_linenr(input)
  local filename, line = input:match('^(.-):(%d+)$')
  if filename and line then
    return filename, tonumber(line)
  else
    return input, 1
  end
end

function util.load_json()
  local f = io.open(json_path, 'r')
  if not f then return {} end
  local ok, data = pcall(vim.fn.json_decode, f:read('*a'))
  f:close()
  return ok and data or {}
end

function util.save_json(data)
  local f = io.open(json_path, 'w')
  if not f then
    vim.notify('Failed to write bookmark.json', vim.log.levels.ERROR)
    return
  end
  f:write(vim.fn.json_encode(data))
  f:close()
end

function util.get_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' then return nil end
  file = vim.uv.fs_realpath(file)
  if not file then return nil end

  local stat = vim.uv.fs_stat(file)
  if not stat or stat.type ~= 'file' then return nil end

  return file
end

function util.remove_file_entries(entries, file)
  for i = #entries, 1, -1 do
    local path = util.split_linenr(entries[i])
    if path == file then table.remove(entries, i) end
  end
  return entries
end

local function echo(msg, hl) vim.api.nvim_echo({ { msg, hl or 'None' } }, true, {}) end

function bookmark.data()
  local map_id = util.get_map_id()
  local data = util.load_json()

  data[map_id] = data[map_id] or {}
  local files = data[map_id]
  return data, files, map_id
end

function bookmark.add(entry)
  local file, line
  if entry then
    file, line = util.split_linenr(entry)
  else
    file = entry or util.get_current_file()
    line = vim.api.nvim_win_get_cursor(0)[1]
  end
  if not file then return end

  local data, files = bookmark.data()

  util.remove_file_entries(files, file)
  table.insert(files, ('%s:%d'):format(file, line))

  -- while #files > MAX_FILES do
  --   table.remove(files)
  -- end

  util.save_json(data)
  if not entry then echo(('Mark added: %s'):format(file), 'DiagnosticHint') end
end

function bookmark.del()
  local file = util.get_current_file()
  if not file then return end

  local data, files, map_id = bookmark.data()

  util.remove_file_entries(files, file)
  data[map_id] = files

  util.save_json(data)
  echo(('Mark removed: %s'):format(file), 'WarningMsg')
end

function bookmark.get() return (util.load_json() or {})[util.get_map_id()] or {} end

-- Open file by indek
function bookmark.open(index)
  local files = bookmark.get()
  local file = files[index]
  if not file then
    vim.notify('No bookmark at index ' .. index, vim.log.levels.WARN)
    return
  end
  local path, line = util.split_linenr(file)
  local current_file = vim.api.nvim_buf_get_name(0)
  if current_file ~= path then vim.cmd('e +' .. line .. ' ' .. vim.fn.fnameescape(path)) end
end

local ns_id = vim.api.nvim_create_namespace('nvimhuda/bookmark')

function bookmark.edit()
  local data, bookmark, map_id = bookmark.data()
  if #bookmark == 0 then return vim.notify('bookmark is empty.', vim.log.levels.WARN) end

  local win = require('nvim-huda.util').win_open(
    vim.tbl_deep_extend('force', require('nvim-huda.util').get_float_opts('sm'), { title = 'Bookmark' })
  )

  vim.wo[win.win_id].number = true

  vim.api.nvim_buf_set_name(win.buf_id, 'bookmark ' .. map_id)
  local cwd = vim.uv.cwd()
  local function relpath(path)
    -- pastikan trailing / supaya aman
    local safe_cwd = cwd:gsub('([%(%)%.%%%+%-%*%?%[%]%^%$])', '%%%1')
    local str = path:gsub('^' .. safe_cwd .. '/', '')
    return str
  end

  local lines = {}
  for _, path in ipairs(bookmark) do
    table.insert(lines, relpath(path))
  end
  vim.api.nvim_buf_set_lines(win.buf_id, 0, -1, false, lines)

  for i, line in ipairs(lines) do
    local fname_start = line:find('[^/]+$')
    local fname_end = line:find(':') and line:find(':') - 1 or #line

    if fname_start then
      if fname_start > 1 then
        vim.api.nvim_buf_set_extmark(win.buf_id, ns_id, i - 1, 0, {
          end_col = fname_start - 1,
          hl_group = 'Comment',
        })
      end
      -- highlight filename
      vim.api.nvim_buf_set_extmark(win.buf_id, ns_id, i - 1, fname_start - 1, {
        end_col = fname_end,
        hl_group = 'Title',
      })
    end

    -- highlight linenr pakai DiagnosticWarn
    local linenr_start = line:find(':(%d+)')
    if linenr_start then
      local linenr_end = #line
      vim.api.nvim_buf_set_extmark(win.buf_id, ns_id, i - 1, linenr_start, {
        end_col = linenr_end,
        hl_group = 'DiagnosticWarn',
      })
    end
  end

  -- Keymap untuk menyimpan bookmark hasil edit
  vim.keymap.set('n', 'q', win.close_win, { buffer = win.buf_id, nowait = true })

  local function open_file()
    local cursor = vim.api.nvim_win_get_cursor(0)
    local file = vim.api.nvim_buf_get_lines(0, cursor[1] - 1, cursor[1], false)[1]
    if not file or file == '' then return end

    local path, line = util.split_linenr(file)
    local real = vim.uv.fs_realpath(path)
    if not real or not vim.uv.fs_stat(real) then
      vim.notify('Invalid path: ' .. line, vim.log.levels.WARN)
      return
    end

    win.close_win()
    vim.schedule(function() vim.cmd('e +' .. line .. ' ' .. vim.fn.fnameescape(real)) end)
  end

  vim.keymap.set('n', '<cr>', open_file, { buffer = true, desc = 'Open file under cursor' })
  vim.keymap.set('n', 'l', open_file, { buffer = true, desc = 'Open file under cursor' })

  vim.keymap.set('n', '=', function()
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local filtered = {}

    for _, file in ipairs(lines) do
      local path, line = util.split_linenr(file)
      local real = vim.uv.fs_realpath(path)
      local stat = real and vim.uv.fs_stat(real)
      if stat and stat.type == 'file' then table.insert(filtered, real .. ':' .. line) end
    end

    data[map_id] = filtered
    util.save_json(data)
    vim.notify('Marks updated.')
  end, { buffer = true, nowait = true, desc = 'Save reordered bookmark' })
end

--------------------------------------------------------------------------------
-- Setup
--------------------------------------------------------------------------------
function bookmark.setup()
  -- Keymap
  map('n', '<Leader>ba', function() bookmark.del() end, { desc = 'Del bookmark' })
  map('n', '<Leader>bd', function() bookmark.add() end, { desc = 'Add bookmark' })
  map('n', '<Leader>be', function() bookmark.edit() end, { desc = 'Edit bookmark' })
  map('n', '<Leader>b1', function() bookmark.open(1) end, { desc = 'Go bookmark 1' })
  map('n', '<Leader>b2', function() bookmark.open(2) end, { desc = 'Go bookmark 2' })
  map('n', '<Leader>b3', function() bookmark.open(3) end, { desc = 'Go bookmark 3' })
  map('n', '<Leader>b4', function() bookmark.open(4) end, { desc = 'Go bookmark 4' })

  local current_file

  -- Autocmd update cursor location when save
  vim.api.nvim_create_autocmd({ 'BufWinLeave', 'BufEnter' }, {
    pattern = '*',
    callback = function(ctx)
      local bufnr = ctx.buf
      if vim.bo[bufnr].buftype ~= '' then return end

      local file = vim.uv.fs_realpath(ctx.file or '')
      if not file or vim.fn.isdirectory(file) == 1 then return end

      if ctx.event == 'BufEnter' then
        local files = bookmark.get()
        for _, path in ipairs(files) do
          local fname = path:match('^[^:]+')
          if fname == file then current_file = path end
        end
      else
        if current_file == file then
          local line = vim.api.nvim_win_get_cursor(0)[1] or 1
          bookmark.add(('%s:%d'):format(file, line))
        end
      end
    end,
  })
end

bookmark.setup()

return bookmark
--------------------------------------------------------------------------------
