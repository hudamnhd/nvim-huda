local util = {}
-- Util ------------------------------------------------------------------------
function util.is_valid_path(path)
  if not path or path == '' then return false end
  local stat = vim.uv.fs_stat(path)
  return stat and (stat.type == 'file' or stat.type == 'directory')
end

function util.is_root() return vim.uv.getuid() == 0 end

function util.get_visual_selection() return vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = 'v' })[1] end

function util.extra_hl(query)
  vim.schedule(function() vim.fn.matchadd('CurSearch', query) end)
end

function util.get_word_or_selection()
  return vim.fn.mode() == 'v' and util.get_visual_selection() or vim.fn.expand('<cword>')
end

function util.get_float_opts(size)
  local columns = vim.o.columns
  local lines = vim.o.lines

  local presets = {
    xl = { wr = 0.9, hr = 0.85, rr = 0.3, cr = 0.5 },
    sm = { wr = 0.6, hr = 0.5, rr = 0.5, cr = 0.5 },
    xs = { wr = 0.4, hr = 0.35, rr = 0.5, cr = 0.5 },
  }

  local cfg = presets[size] or presets.xl

  local width = math.floor(columns * cfg.wr)
  local height = math.floor(lines * cfg.hr)
  local row = math.floor((lines - height) * cfg.rr)
  local col = math.floor((columns - width) * cfg.cr)

  return {
    relative = 'editor',
    style = 'minimal',
    row = row,
    col = col,
    width = width,
    height = height,
    border = 'single',
    title = '',
    title_pos = 'center',
  }
end

function util.win_open(opts, buf_id)
  local prev_win_id = vim.api.nvim_get_current_win()
  if not util.valid_buf(buf_id) then buf_id = vim.api.nvim_create_buf(false, true) end

  local win_id = vim.api.nvim_open_win(buf_id, true, opts)

  local function close_win()
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

function util.valid_win(win_id) return win_id and vim.api.nvim_win_is_valid(win_id) end
function util.valid_buf(buf_id) return buf_id and vim.api.nvim_buf_is_valid(buf_id) end

function util.buf_delete(buf_id)
  if util.valid_buf(buf_id) then pcall(vim.api.nvim_buf_delete, buf_id, { force = true }) end
end
function util.win_close(win_id)
  if util.valid_win(win_id) then pcall(vim.api.nvim_win_close, win_id, true) end
end
function util.win_focus(win_id)
  if util.valid_win(win_id) then pcall(vim.api.nvim_set_current_win, win_id) end
end

return util
--------------------------------------------------------------------------------

