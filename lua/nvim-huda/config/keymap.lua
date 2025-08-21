--------------------------------------------------------------------------------
-- Keymap
--------------------------------------------------------------------------------
local api, fn, expr = vim.api, vim.fn, { expr = true }

-- │Leader Key│
vim.g.mapleader = vim.keycode('<space>')
vim.g.maplocalleader = vim.keycode('<space>')

local setup = function(my)
  -- │Disabled Keys│
  map('nx', 's', '<Nop>')
  map('nx', '<C-z>', '<Nop>')
  map('nx', '<Space>', '<Nop>')

  -- │Change Redo│
  map('n', '<S-u>', '<C-r>')
  map('n', '<C-r>', '<Nop>')

  -- │Blackhole keys│
  map('n', 'd', '"_d')
  map('n', 'c', '"_c')
  map('nx', 'x', '"_x')

  -- |Undo-break point|
  map('i', ',', ',<C-g>u')
  map('i', ';', ';<C-g>u')
  map('i', '.', '.<C-g>u')

  -- │q key│
  map('n', 'q', my.qkey, expr)

  -- │Swap Command-Line│
  map('nx', ',', ':')
  map('nx', ':', ',')
  map('nx', '@,', '@:')

  -- │Better indent│
  map('x', '>', '>gv')
  map('x', '<', '<gv')

  -- │Smart insert│
  map('x', 'I', my.nice_block_I, expr)
  map('x', 'A', my.nice_block_A, expr)
  map('n', 'i', my.smart_insert, expr)

  -- |Join lines and keep cursor|
  map('n', 'J', my.join_line, expr)

  -- │Window Navigation│
  map('n', '<A-w>', '<C-w>w')
  map('t', '<A-w>', '<C-Bslash><C-n><C-w>w')

  -- │Navigation│
  map('nx', 'j', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'j']], expr)
  map('nx', 'k', [[(v:count > 1 ? 'm`' . v:count : 'g') . 'k']], expr)
  map('nx', '^', my.smart_home, expr)
  map('nx', '$', my.smart_end, expr)
  map('nx', '_', my.goto_star_end, expr)

  -- |Move lines up/down|
  map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
  map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
  map('x', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down' })
  map('x', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up' })

  -- |Tab navigation|
  map('n', '<leader>]', '<cmd>tabnext<cr>', { desc = 'Tab Next' })
  map('n', '<leader>[', '<cmd>tabprevious<cr>', { desc = 'Tab Previous' })
  map('n', '<leader>tc', '<cmd>tabclose<cr>', { desc = 'Close tab page' })
  map('n', '<leader>ts', '<cmd>tab split<cr>', { desc = 'New tab page' })
  map('n', '<leader>to', '<cmd>tabonly<cr>', { desc = 'Close other tab pages' })

  -- |g key|
  map('nx', 'g<C-j>', my.copy_line, { expr = true, desc = 'Copy line' })
  map('n', 'g<C-v>', '`[v`]', { desc = 'Visual select last yank/paste' })

  -- │Clipboard│
  map('nx', 'gy', '"+y', { desc = 'Yank to system clipboard' })
  map('nx', 'gp', '"+p', { desc = 'Paste from system clipboard' })

  -- │Yank / Paste│
  map('x', 'p', my.visual_paste, expr)
  map('n', 'Y', my.pre_yank(true), expr)
  map('nx', 'y', my.pre_yank(false), expr)

  -- │Case tranform│
  map('n', 'cu', my.switch_case('upper'))
  map('n', 'cl', my.switch_case('lower'))
  map('n', 'ct', my.switch_case('title'))
  map('n', 'cn', my.switch_case('snake'))
  map('n', 'cm', my.switch_case('camel'))

  -- │Change text│
  map('nx', '<BS>', my.change_and_repeatable, expr)

  -- │Search Replace│
  map('x', '<F5>', my.search_visual_mode, { desc = 'Search inside visual selection' })
  map('n', '<F5>', my.subs_last_visual, { desc = 'Substitute last visual' })
  map('n', '<F6>', my.subs_last_search, { desc = 'Substitute last search' })
  map('nx', '<F7>', my.smart_substitute, { expr = true, desc = 'Substitute word or visual selection' })

  -- │Cmdline│Map
  map('c', '<F1>', [[\(.*\)]], { desc = 'Regex capture all' })
  map('c', '<F2>', [[.\{-}]], { desc = 'Regex fuzzy match' })
  map('c', '<C-s>', my.ctrl_s_cmdline, { expr = true })

  -- │Terminal Mode│
  map('t', '<C-Bslash>', '<C-Bslash><C-n>')
  map('t', '<A-r>', my.term_reg_paste, expr)

  -- │Inc/Dec│
  map('n', '<C-a>', my.ctrl_ax('<C-a>'), { desc = 'Increment or swap boolean' })
  map('n', '<C-x>', my.ctrl_ax('<C-x>'), { desc = 'Decrement or swap boolean' })

  -- │Miscellaneous│
  map('n', '<Leader>M', my.cmd('messages'), { desc = 'Show messages' })
  map('n', '<Leader>W', my.cmd('setlocal wrap! wrap?'), { desc = "Toggle 'wrap'" })
  map('n', '<Leader>L', my.cmd('My toggle_line_numbers'), { desc = "Toggle 'line number'" })
  map('n', '<Leader>T', my.cmd('botright 14split term://$SHELL'), { desc = 'Open split terminal' })
  map('n', '<Leader>K', my.cmd('My'),  { desc = 'My command' })

  -- │EOL Delimiter Toggle/Replace│
  local delimiter_chars = { ',', ';', '.' }
  for _, char in ipairs(delimiter_chars) do
    map('n', 'd' .. char, function()
      local line = api.nvim_get_current_line()
      local last = line:sub(-1)
      local new = line

      if last == char then
        new = line:sub(1, -2)
      elseif vim.tbl_contains(delimiter_chars, last) then
        new = line:sub(1, -2) .. char
      else
        new = line .. char
      end

      api.nvim_set_current_line(new)
    end, {})
  end

  -- │Macro│
  do
    local reg = 'r'
    local toggle_key = '<Leader><F8>'
    fn.setreg(reg, '')
    map('n', toggle_key, function() my.start_or_stop_recording(toggle_key, reg) end, { desc = ' Start/stop recording' })
    map('n', '<F8>', function() my.play_recording(reg) end, { desc = 'Play recording' })
  end
end

--------------------------------------------------------------------------------
-- Setup Readline on InsertEnter and CmdlineEnter Event
--------------------------------------------------------------------------------
api.nvim_create_autocmd({ 'InsertEnter', 'CmdlineEnter' }, {
  once = true,
  callback = vim.schedule_wrap(function()
    local line, col, pos, cmdline = fn.getline, fn.col, fn.getcmdpos, fn.getcmdline
    map('ci', '<C-b>', '<Left>')
    map('c', '<C-a>', '<Home>')
    map('i', '<C-a>', '<C-o>^')
    map('c', '<C-d>', function() return pos() > #cmdline() and '<C-d>' or '<Del>' end, expr)
    map('i', '<C-d>', function() return col('.') > #line('.') and '<C-d>' or '<Del>' end, expr)
    map('c', '<C-f>', function() return pos() > #cmdline() and vim.o.cedit or '<Right>' end, expr)
    map('i', '<C-f>', function() return col('.') > #line('.') and '<C-f>' or '<Right>' end, expr)
    map('i', '<C-e>', function() return col('.') > #line('.') or fn.pumvisible() == 1 and '<C-e>' or '<End>' end, expr)
  end),
})

local H = {}
--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

local escape_characters = [[=.^$*+?()[]{}|\-]]

-- Move cursor left by count
local function left(count) return string.rep('<left>', count) end

-- Create <Cmd>...<CR> command string
function H.cmd(cmd) return ('<Cmd>%s<CR>'):format(cmd) end

-- taken from https://www.reddit.com/r/neovim/comments/1exnko2/comment/ljaijfl/
function _G.get_visual_selection(escape)
  -- table.concat(fn.getregion(fn.getpos('v'), fn.getpos('.')), '\n')
  local text
  if fn.mode():match('[vV]') then
    text = fn.getregion(fn.getpos('.'), fn.getpos('v'), { type = 'v' })[1]
  else
    text = fn.getregion(fn.getpos("'<"), fn.getpos("'>"), { type = 'v' })[1]
  end
  assert(text)
  return escape ~= false and fn.escape(text, escape_characters) or text
end

-- Get a single character
local function getchar()
  local char = fn.getchar()
  if type(char) == 'number' then
    local char_str = fn.nr2char(char)
    return char_str
  end
  return nil
end

-- Utils Operator Function
local function get_mark(mark)
  local pos = api.nvim_buf_get_mark(0, mark)
  if pos[1] == 0 then return nil end
  pos[2] = pos[2] + 1
  return pos
end

local function get_str(mode, first_pos, last_pos)
  -- different types of operator funcs need different ways of getting lines
  if mode == 'line' then
    return api.nvim_buf_get_lines(0, first_pos[1] - 1, last_pos[1], false)
  elseif mode == 'char' then
    return api.nvim_buf_get_text(
      0,
      first_pos[1] - 1, -- row
      first_pos[2] - 1, -- col
      last_pos[1] - 1, -- row
      last_pos[2], -- col
      {}
    )
  else
    print('mode ' .. mode .. ' is un-supported')
    return
  end
end

local function create_opfunc(callback, allow_multiline)
  return function(mode)
    local first_pos, last_pos = get_mark('['), get_mark(']')
    local lines = get_str(mode, first_pos, last_pos)
    if not lines then return end

    if allow_multiline or #lines > 1 then
      return callback(lines)
    else
      return callback(lines[1])
    end
  end
end

function H.opfunc(callback, opts)
  opts = opts or {}
  local allow_multiline = opts.multiline or false
  _my._opfunc = create_opfunc(callback, allow_multiline)
  vim.go.operatorfunc = 'v:lua._my._opfunc'
  return 'g@'
end

-- Substitute ------------------------------------------------------------------
function H.smart_substitute()
  local mode = fn.mode()
  local selection_cmd = H.cmd_visual_selection('true')
  local base_cmd, flags = ':s/', '/gI'

  if mode == 'n' then -- Cword normal
    return [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI]] .. left(3)
  elseif mode == 'V' then -- Linewise visual
    return base_cmd .. [[\V/]] .. flags .. left(4)
  elseif mode == '\22' then -- Blockwise visual (CTRL-V)
    return base_cmd .. [[\%V/]] .. flags .. left(4)
  else -- Characterwise visual
    return string.format(':<C-u>%%s/\\v%s/%s%s%s', selection_cmd, selection_cmd, flags, left(3))
  end
end

H.cmd_visual_selection = function(esc) return '<C-r>=luaeval("get_visual_selection(' .. esc .. ')")<CR>' end
H.subs_last_search = ':%s///gI' .. left(3)
H.substitute_cword = [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI]] .. left(3)
H.substitute_cWORD = [[:%s/\V<C-r><C-a>/<C-r><C-a>/gI]] .. left(3)
H.subs_last_visual = [[:'<,'>s/\<<C-r><C-w>\>//gI]] .. left(3)
H.search_visual_mode = '<Esc>/\\%V'

-- Text Editing ----------------------------------------------------------------
function H.join_line() return 'mz' .. vim.v.count1 .. 'J`z' end
function H.visual_paste() return 'pgv"' .. vim.v.register .. 'y' end
function H.term_reg_paste() return '<C-\\><C-n>"' .. fn.nr2char(fn.getchar()) .. 'pi' end
function H.nice_block_I() return fn.mode():match('[vV]') and '<C-v>^o^I' or 'I' end
function H.nice_block_A() return fn.mode():match('[vV]') and '<C-v>1o$A' or 'A' end

function H.smart_insert()
  local mode = api.nvim_get_mode().mode
  if mode ~= 'n' then return 'i' end
  local line = api.nvim_get_current_line()
  return vim.trim(line) == '' and '"_cc' or 'i'
end

function H.change_and_repeatable()
  if vim.bo.buftype ~= '' then return end
  if fn.mode():match('[n]') then
    return '*N"_cgn'
  elseif fn.mode():match('[v]') then
    local text = get_visual_selection(false)
    fn.setreg('/', '\\V' .. text)
    return '<Esc>"_cgn'
  end
end

function H.start_or_stop_recording(toggle_key, reg)
  local is_not_recording = fn.reg_recording() == ''
  if is_not_recording then
    vim.cmd.normal({ 'q' .. reg, bang = true })
    return
  end

  local previous_macro = fn.getreg(reg)
  vim.cmd.normal({ 'q', bang = true })

  local current_macro = fn.getreg(reg):sub(1, -(#toggle_key + 1))
  if current_macro ~= '' then
    fn.setreg(reg, current_macro)
    local macro_display = fn.keytrans(current_macro)
    print(macro_display)
  else
    fn.setreg(reg, previous_macro)
    print('Aborted.')
  end
end

---@param reg string vim register (single letter)
function H.play_recording(reg)
  local has_recording = fn.getreg(reg) ~= ''
  if has_recording then
    vim.cmd.normal({ '@' .. reg, bang = true })
  else
    print('There is no recording.')
  end
end

function H.ctrl_ax(key)
  return function()
    local toggle_map = {
      ['true'] = 'false',
      ['false'] = 'true',
      ['on'] = 'off',
      ['off'] = 'on',
      ['and'] = 'or',
      ['or'] = 'and',
    }

    local current_word = fn.expand('<cword>')
    local replacement = toggle_map[current_word]

    if replacement then
      local cursor_pos = api.nvim_win_get_cursor(0)
      vim.cmd.normal({ '"_ciw' .. replacement, bang = true })
      api.nvim_win_set_cursor(0, cursor_pos)
    else
      vim.cmd.execute('"normal! ' .. vim.v.count1 .. '\\' .. key .. ' "')
    end
  end
end

local cache_copy_line = nil

H.copy_line = function(cache)
  if not cache then
    cache_copy_line = nil
    vim.go.operatorfunc = 'v:lua._my.callback_copy_line'
    return 'g@l'
  end
  if cache_copy_line then vim.cmd(cache_copy_line) end
end

_my.callback_copy_line = function(mode)
  if mode == 'char' then
    local line, col = unpack(api.nvim_win_get_cursor(0))
    if not cache_copy_line then cache_copy_line = 't' .. line end
    H.copy_line(cache_copy_line)
    api.nvim_win_set_cursor(0, { line + 1, col })
  else
    local line, col = unpack(api.nvim_win_get_cursor(0))
    local start_pos = fn.getpos("'<")[2]
    local end_pos = fn.getpos("'>")[2]

    local top = math.min(start_pos, end_pos)
    local bottom = math.max(start_pos, end_pos)
    local diff = bottom - top

    if not cache_copy_line then cache_copy_line = top .. ',' .. bottom .. 't+' .. diff end
    H.copy_line(cache_copy_line)
    api.nvim_win_set_cursor(0, { line + 1 + diff, col })
  end
end

function H.toggle_case()
  vim.o.ignorecase = not vim.o.ignorecase
  vim.o.smartcase = not vim.o.smartcase
  return ' <Bs>' -- Refresh search
end

-- Case Conversions ------------------------------------------------------------
function H.switch_case(mode)
  return function()
    local line, col = unpack(api.nvim_win_get_cursor(0))
    local word = fn.expand('<cword>')
    local start = fn.matchstrpos(fn.getline('.'), '\\k*\\%' .. (col + 1) .. 'c\\k*')[2]

    local function camel(s) return s:find('_') and s:gsub('_(%l)', string.upper) or nil end
    local function snake(s) return s:find('[a-z][A-Z]') and s:gsub('([a-z])([A-Z])', '%1_%2'):lower() or nil end

    local cases = {
      camel = camel,
      snake = snake,
      upper = string.upper,
      lower = string.lower,
      title = function(s) return s:sub(1, 1):upper() .. s:sub(2):lower() end,
    }

    local f = cases[mode]
    if not f then return print('Unknown mode: ' .. mode) end

    local result = f(word)
    if not result or result == word then return print(result or 'No change') end

    api.nvim_buf_set_text(0, line - 1, start, line - 1, start + #word, { result })
  end
end

-- Pre yank --------------------------------------------------------------------
-- Cursor restored in autocmd Hl yank
function H.pre_yank(normal_only)
  return function()
    vim.b.cursor_pre_yank = api.nvim_win_get_cursor(0)
    return normal_only and 'y_' or 'y'
  end
end

-- Remap q, --------------------------------------------------------------------
function H.qkey()
  local rec = fn.reg_recording()
  if rec ~= '' then return 'q' end
  local char = getchar()
  if char == ',' then
    return 'q:'
  else
    return 'q' .. char
  end
end

-- Smart Home/End Key ----------------------------------------------------------
function H.smart_home()
  local col = fn.col('.') - 1
  local line = fn.getline('.')
  local str_before_cursor = line:sub(1, col)

  local wrap_prefix = vim.wo.wrap and 'g' or ''

  if str_before_cursor:match('^%s*$') then
    return wrap_prefix .. '0'
  else
    return wrap_prefix .. '^'
  end
end

function H.smart_end() return vim.wo.wrap and 'g$' or '$' end

function H.goto_star_end()
  local col = fn.col('.')
  local line = fn.getline('.')
  local first_nonblank = fn.match(line, '\\S') + 1
  local last_nonblank = #line

  if col == last_nonblank + 1 then
    return '^'
  elseif col == first_nonblank then
    return '$'
  else
    return '^'
  end
end


function H.substitute_opfunc()
  local mode = fn.mode()
  local base_cmd, flags = ':s/', '/gI'

  if mode == 'V' then -- Visual line mode
    return base_cmd .. [[\V/]] .. flags .. left(4)
  elseif mode == '\22' then -- Visual block mode (Ctrl-V)
    return base_cmd .. [[\%V/]] .. flags .. left(4)
  else -- Visual charwise atau operatorfunc charwise
    return H.opfunc(function(result)
      local left = vim.keycode('<Left>')
      local escaped = fn.escape(result, escape_characters)
      local command = ':%s/\\v' .. escaped .. '/' .. result .. '/gI'
      api.nvim_feedkeys(command .. string.rep(left, 3), 'n', true)
    end)
  end
end

-- Cmdline helper --------------------------------------------------------------
local last_mode = nil
function H.command_mode()
  last_mode = vim.api.nvim_get_mode().mode
  return ':'
end

function H.ctrl_s_cmdline()
  local char = getchar()
  local action = {
    [' '] = [[\s\+]],
    h = [[<C-r>=expand('%:h') . '/'<CR>]],
    f = [[<C-r>=expand('%:f')<CR>]],
    t = [[s/\v(\w)(\w*)/\u\1\L\2/g]],
    w = [[\<\><left><left>]],
    v = H.cmd_visual_selection('false'),
    c = H.toggle_case(),
  }
  return action[char] or char
end
--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------
api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = vim.schedule_wrap(function() setup(H) end),
})

--------------------------------------------------------------------------------
