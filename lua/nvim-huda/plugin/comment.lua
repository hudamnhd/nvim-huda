local M = {}

local function get_width() return vim.o.textwidth > 0 and vim.o.textwidth or 80 end

-- Insert a comment section
local function insert_section(symbol, width)
  symbol = symbol or '='
  width = get_width()

  local comment_str = vim.bo.commentstring
  local fill = string.rep(symbol, width - (comment_str:len() - 2))
  local comment_line = comment_str:format(fill)

  vim.fn.append(vim.fn.line('.'), comment_line)
  local start_col = comment_str:find('%%s')
  vim.fn.cursor(vim.fn.line('.') + 1, start_col)
  vim.cmd('startreplace')
end

vim.api.nvim_create_user_command('InsertSection', function(opts)
  local symbol = opts.args:match('%S+') or '-'
  local width = tonumber(opts.args:match('%d+')) or 79
  insert_section(symbol, width)
end, {
  nargs = '*',
  complete = function() return { '=', '-', '*', '#', '~' } end,
  desc = 'Insert comment section line',
})

local function get_comment_str()
  local comment_str = vim.bo.commentstring
  if not comment_str or comment_str == '' then
    vim.notify('No commentstring for ' .. vim.bo.ft, vim.log.levels.WARN, { title = 'Comment' })
    return nil
  end
  return comment_str
end

local filetypes_with_padding = { 'css', 'scss' }

function M.comment_hr()
  local comment_str = get_comment_str()
  if not comment_str then return end

  local cur_line = vim.api.nvim_win_get_cursor(0)[1]
  local indent = ''
  local line_idx = cur_line

  repeat
    local line = vim.api.nvim_buf_get_lines(0, line_idx - 1, line_idx, true)[1]
    indent = line:match('^%s*')
    line_idx = line_idx - 1
  until line ~= '' or line_idx == 0

  local textwidth = get_width()
  local indent_len = vim.bo.expandtab and #indent or #indent * vim.bo.tabstop
  local comment_len = #(comment_str:format(''))
  local hr_len = textwidth - (indent_len + comment_len)

  local hr_char = comment_str:find('%-') and '-' or '-'
  local hr_line = comment_str:format(hr_char:rep(hr_len))

  if not vim.list_contains(filetypes_with_padding, vim.bo.ft) then hr_line = hr_line:gsub(' ', hr_char) end

  local final_line = indent .. hr_line
  if vim.bo.ft == 'markdown' then final_line = '---' end

  vim.api.nvim_buf_set_lines(0, cur_line, cur_line, true, { final_line, '' })
  vim.api.nvim_win_set_cursor(0, { cur_line + 1, #indent })
end

function M.duplicate_line_as_comment()
  local comment_str = get_comment_str()
  if not comment_str then return end

  local lnum, col = unpack(vim.api.nvim_win_get_cursor(0))
  local current_line = vim.api.nvim_get_current_line()
  local indent, content = current_line:match('^(%s*)(.*)')
  local commented = indent .. comment_str:format(content)

  vim.api.nvim_buf_set_lines(0, lnum - 1, lnum, false, { commented, current_line })
  vim.api.nvim_win_set_cursor(0, { lnum + 1, col })
end

---@param where "eol"|"above"|"below"
function M.add_comment(where)
  local comment_str = get_comment_str()
  if not comment_str then return end

  local lnum = vim.api.nvim_win_get_cursor(0)[1]

  if where == 'above' or where == 'below' then
    if where == 'above' then lnum = lnum - 1 end
    vim.api.nvim_buf_set_lines(0, lnum, lnum, true, { '' })
    lnum = lnum + 1
    vim.api.nvim_win_set_cursor(0, { lnum, 0 })
  end

  local place_at_end = comment_str:find('%%s$') ~= nil
  local line = vim.api.nvim_get_current_line()
  local is_empty = line == ''

  local indent = ''
  if is_empty then
    local i = lnum
    local last = vim.api.nvim_buf_line_count(0)
    while vim.fn.getline(i) == '' and i < last do
      i = i + 1
    end
    indent = vim.fn.getline(i):match('^%s*')
  end

  local spacing = vim.list_contains(filetypes_with_padding, vim.bo.ft) and '  ' or ' '
  local base = is_empty and indent or line .. spacing
  comment_str = comment_str:gsub('%%s', ''):gsub(' *$', '') .. ' '

  vim.api.nvim_set_current_line(base .. comment_str)

  if place_at_end then
    vim.cmd.startinsert({ bang = true })
  else
    local cursor_pos = #base + vim.bo.commentstring:find('%%s') - 1
    vim.api.nvim_win_set_cursor(0, { lnum, cursor_pos })
    vim.cmd.startinsert()
  end
end

-- Mappings
map('n', 'gci', function() insert_section('-') end, { desc = 'Insert Section' })
map('n', 'gcd', M.duplicate_line_as_comment, { desc = 'Duplicate Comment' })
map('n', 'gch', M.comment_hr, { desc = 'Comment hr' })
map('n', 'gce', function() M.add_comment('eol') end, { desc = 'Comment eol' })
map('n', 'gca', function() M.add_comment('below') end, { desc = 'Comment below' })
map('n', 'gcb', function() M.add_comment('above') end, { desc = 'Comment above' })

return M
--------------------------------------------------------------------------------

