-------------------------------------------------------------------------------
-- A minimal yank history browser with persistent storage support.
-------------------------------------------------------------------------------
local M = {}
local history_path = vim.fn.stdpath('cache') .. '/yank_history.json'
local max_items = 50
local history_cache = nil

-- Load yank history from file (with in-memory cache)
local function load_history()
  if history_cache then return history_cache end

  local f = io.open(history_path, 'r')
  if not f then
    history_cache = {}
    return history_cache
  end

  local content = f:read('*a')
  f:close()

  local ok, result = pcall(vim.fn.json_decode, content)
  history_cache = ok and result or {}
  return history_cache
end

-- Save yank history to file
local function save_history(history)
  local f = io.open(history_path, 'w')
  if not f then return end
  f:write(vim.fn.json_encode(history))
  f:close()
  history_cache = history -- update cache
end

-- Delete yank history
function M.clear()
  history_cache = {}
  save_history(history_cache)
  vim.notify('Yank history cleared', vim.log.levels.INFO)
end

-- Delete yank history by index
function M.remove(index)
  local history = load_history()
  if index < 1 or index > #history then
    vim.notify('Invalid index', vim.log.levels.WARN)
    return
  end
  table.remove(history, index)
  save_history(history)
  vim.schedule(function() vim.notify('Removed yank history item at index ' .. index, vim.log.levels.INFO) end)
end

-- Force reload history
function M.reload_cache()
  history_cache = nil
  return load_history()
end

-- Add a new yank to history
function M.save_yank(text)
  local history = load_history()

  -- Normalize yank (flatten to single line if needed)
  local yanked_text = table.concat(text, '\n')
  if yanked_text:match('^%s*$') then return end
  -- Hindari duplikat berurutan
  if history[1] ~= yanked_text then table.insert(history, 1, yanked_text) end

  -- Potong agar max 50
  while #history > max_items do
    table.remove(history)
  end

  save_history(history)
end

-- Load history untuk dipakai kembali (opsional dipanggil dari luar)
function M.load() return load_history() end

vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    local event = vim.v.event
    if event.operator == 'y' then M.save_yank(event.regcontents) end
  end,
})

-- show window split
function M.show_in_split()
  local items = M.load()
  local buf = vim.api.nvim_create_buf(false, true)
  local lines = {}
  local item_starts = {} -- line index where each item starts

  for i, item in ipairs(items) do
    table.insert(item_starts, #lines + 1)
    for line in item:gmatch('([^\n]*)\n?') do
      table.insert(lines, line)
    end
    table.insert(lines, string.rep('─', 20))
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  vim.cmd('split')
  vim.api.nvim_win_set_buf(0, buf)

  -- Store item_starts in buf var
  vim.api.nvim_buf_set_var(buf, 'item_starts', item_starts)
  vim.api.nvim_buf_set_var(buf, 'yank_items', items)

  -- mappings
  vim.keymap.set('n', 'j', M.move_next, { buffer = buf, unique = false })
  vim.keymap.set('n', 'k', M.move_prev, { buffer = buf, unique = false })
  vim.keymap.set('n', 'q', vim.cmd.bw, { buffer = buf, unique = false })
  vim.keymap.set('n', 'd', M.delete_under_cursor, { buffer = buf, unique = false, nowait = true })
  vim.keymap.set('n', '<CR>', M.put_item, { buffer = buf, unique = false })

  vim.bo[buf].filetype = 'yank_history'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].modifiable = true
end

function M.move_next()
  local buf = vim.api.nvim_get_current_buf()
  local item_starts = vim.api.nvim_buf_get_var(buf, 'item_starts')
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  for _, line in ipairs(item_starts) do
    if line > cursor then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
  -- stay on last
end

function M.move_prev()
  local buf = vim.api.nvim_get_current_buf()
  local item_starts = vim.api.nvim_buf_get_var(buf, 'item_starts')
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  for i = #item_starts, 1, -1 do
    local line = item_starts[i]
    if line < cursor then
      vim.api.nvim_win_set_cursor(0, { line, 0 })
      return
    end
  end
end

function M.put_item()
  local buf = vim.api.nvim_get_current_buf()
  local item_starts = vim.api.nvim_buf_get_var(buf, 'item_starts')
  local yank_items = vim.api.nvim_buf_get_var(buf, 'yank_items')
  local cursor = vim.api.nvim_win_get_cursor(0)[1]

  local index = 1
  for i, line in ipairs(item_starts) do
    if cursor >= line then
      index = i
    else
      break
    end
  end

  local lines = vim.split(yank_items[index], '\n', { plain = true })
  vim.api.nvim_command('close') -- close split
  vim.api.nvim_put(lines, 'l', true, true)
end

function M.delete_under_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local item_starts = vim.api.nvim_buf_get_var(buf, 'item_starts')
  local cursor = vim.api.nvim_win_get_cursor(0)[1]

  local index = 1
  for i, line in ipairs(item_starts) do
    if cursor >= line then
      index = i
    else
      break
    end
  end

  M.remove(index)

  vim.api.nvim_buf_delete(buf, { force = true })
  M.show_in_split()
end

vim.keymap.set('n', 'yh', function() M.show_in_split() end, { desc = 'Show yank history' })

return M
