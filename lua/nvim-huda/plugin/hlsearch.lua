--------------------------------------------------------------------------------
-- Auto nohl
--------------------------------------------------------------------------------
local ns_id = vim.api.nvim_create_namespace('NHAutoNohl')

--- Shows virtual text with search match count
---@param mode? "clear"
local function show_search_count(mode)
  vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
  if mode == 'clear' then return end

  local cursor_row = vim.api.nvim_win_get_cursor(0)[1]
  local count = vim.fn.searchcount()
  if vim.tbl_isempty(count) or count.total == 0 then return end

  local virt_text = (' %d/%d '):format(count.current, count.total)
  local line = vim.api.nvim_get_current_line():gsub('\t', string.rep(' ', vim.bo.shiftwidth))
  local line_is_full = #line + 5 >= vim.api.nvim_win_get_width(0)

  vim.api.nvim_buf_set_extmark(0, ns_id, cursor_row - 1, 0, {
    virt_text = { { virt_text, 'IncSearch' }, { string.rep(' ', line_is_full and 5 or 0) } },
    virt_text_pos = line_is_full and 'right_align' or 'eol',
    priority = 200,
  })
end

vim.keymap.set('', '*', function()
  if vim.fn.mode():match('[n]') then
    local text = vim.fn.expand('<cword>')
    vim.fn.setreg('/', '\\<' .. text .. '\\>')
  elseif vim.fn.mode():match('[v]') then
    local text = get_visual_selection(false)
    vim.fn.setreg('/', '\\V' .. text)
  end
  vim.opt.hlsearch = true
  show_search_count()
end, { silent = true, desc = '*, but stay on the current search result' })

-- Auto toggle hlsearch & display match count
vim.on_key(function(key)
  key = vim.fn.keytrans(key)

  local is_cmdline_search = vim.fn.getcmdtype():find('[/?]') ~= nil
  local is_normal_mode = vim.api.nvim_get_mode().mode == 'n'

  local started_search = (key == '/' or key == '?') and is_normal_mode
  local confirmed_search = key == '<CR>' and is_cmdline_search
  local cancelled_search = key == '<Esc>' and is_cmdline_search
  local is_search_nav = vim.tbl_contains({ 'n', 'N', '*', '#' }, key)

  if not (started_search or confirmed_search or cancelled_search or is_normal_mode) then return end

  if cancelled_search or (not is_search_nav and not confirmed_search) then
    vim.opt.hlsearch = false
    show_search_count('clear')
  elseif is_search_nav or confirmed_search or started_search then
    vim.opt.hlsearch = true
    vim.defer_fn(show_search_count, 1)
  end
end, vim.api.nvim_create_namespace('NHAutoNohlAndCount'))

--------------------------------------------------------------------------------
