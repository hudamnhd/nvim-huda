--------------------------------------------------------------------------------
-- Keymap
--------------------------------------------------------------------------------
local map = vim.keymap.set

-- │Leader Key│
vim.g.mapleader = vim.keycode('<space>')
vim.g.maplocalleader = vim.keycode('<space>')

local setup = function(my)
  -- │Disabled Keys│
  map({ 'n', 'x' }, 's', '<Nop>')
  map({ 'n', 'x' }, '<Space>', '<Nop>')

  -- │Change Redo│
  map('n', '<S-u>', '<C-r>')
  map('n', '<C-r>', '<Nop>')

  -- │Blackhole keys│
  map('n', 'd', '"_d')
  map('n', 'c', '"_c')
  map({ 'n', 'x' }, 'x', '"_x')

  -- |Undo-break point|
  map('i', ',', ',<C-g>u')
  map('i', ';', ';<C-g>u')
  map('i', '.', '.<C-g>u')

  -- │q key, make q, not pending for open cmdline│
  map('n', 'q', my.qkey, { expr = true })

  -- │Swap Command-Line│
  map({ 'n', 'x' }, '@,', '@:')
  map({ 'n', 'x' }, ',', ':')
  map({ 'n', 'x' }, ':', ',')

  -- │Buffer delete│
  map('n', '<Leader>q', my.cmd('bd'), { desc = 'Delete buffer' })

  -- │Window Navigation│
  map('n', '<A-w>', '<C-w>w', { desc = 'Next window' })
  map('n', '<A-w>', '<C-w>w', { desc = 'Next window' })
  map('n', '<A-Tab>', '<C-w>w', { desc = 'Next window' })
  map('t', '<A-Tab>', '<C-Bslash><C-n><C-w>w', { desc = 'Next window (terminal)' })

  -- │Navigation│
  map({ 'n', 'x' }, 'j', [[(v:count > 5 ? "m'" . v:count : "") . 'j']], { desc = 'Line up', expr = true })
  map({ 'n', 'x' }, 'k', [[(v:count > 5 ? "m'" . v:count : "") . 'k']], { desc = 'Line down', expr = true })
  map({ 'n', 'x' }, '^', my.smart_home, { expr = true, desc = 'Smart Home' })
  map({ 'n', 'x' }, '$', my.smart_end, { expr = true, desc = 'Smart End' })

  -- │Enhancements│
  map('v', '>', '>gv')
  map('v', '<', '<gv')
  map('v', 'I', my.nice_block_I, { expr = true })
  map('v', 'A', my.nice_block_A, { expr = true })
  map('n', 'i', my.smart_insert, { expr = true })

  -- │Line Manipulation│
  map('n', 'J', my.join_line, { desc = 'Join lines and keep cursor', expr = true })
  map('', '<Leader>t.', NH.copy_line, { desc = 'Copy line (default t. or t+)', expr = true })

  -- |Move lines up/down|
  map('n', '<A-j>', "<cmd>execute 'move .+' . v:count1<cr>==", { desc = 'Move Down' })
  map('n', '<A-k>', "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = 'Move Up' })
  map('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = 'Move Down' })
  map('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = 'Move Up' })

  -- │Clipboard & Yank / Paste│
  map('x', 'p', my.safe_paste, { desc = 'Paste without overwriting register', expr = true })
  map('n', 'gV', '`[v`]', { desc = 'Visual select last yank/paste' })
  map({ 'n', 'x' }, 'gy', '"+y', { desc = 'Yank to system clipboard' })
  map({ 'n', 'x' }, 'gp', '"+p', { desc = 'Paste from system clipboard' })
  map({ 'n', 'x' }, '<C-r>', my.register, { desc = 'Register', expr = true })

  -- │Case Transformation│
  map('n', 'cu', my.switch_case('upper'))
  map('n', 'cl', my.switch_case('lower'))
  map('n', 'ct', my.switch_case('title'))
  map('n', 'cn', my.switch_case('snake'))
  map('n', 'cm', my.switch_case('camel'))

  -- │Change text│
  map({ 'n', 'x' }, '<BS>', my.change_and_repeatable, { desc = 'Change word/selection', expr = true })

  -- │Macro Utilities│
  map('n', '<F7>', my.macro_word(true), { desc = 'Start macro for word', expr = true })
  map('n', '<F8>', my.macro_word(false), { desc = 'End/replay macro', expr = true })

  -- │Substitute│MAP
  map('n', 'gsv', my.substitute_lvisual, { desc = 'Substitute last visual' })
  map('n', 'gsr', my.substitute_lsearch, { desc = 'Substitute last search' })
  map('n', 'gsw', my.substitute_cword, { desc = 'Substitute word' })
  map('n', 'gsW', my.substitute_cWORD, { desc = 'Substitute WORD' })
  map('x', 'gs', my.substitute_visual, { desc = 'Substitute selection', expr = true })

  -- │Cmdline / Search / Regex│
  map('x', 'gf', my.gf, { desc = 'Search inside visual selection', expr = true })
  map('c', '%%', [[getcmdtype() == ':' ? expand('%:h') . '/' : '%%']], { expr = true })
  map('c', '<F1>', [[\(.*\)]], { desc = 'Regex capture all' })
  map('c', '<F2>', [[.\{-}]], { desc = 'Regex fuzzy match' })
  map('c', '<F3>', [[\<\><left><left>]], { desc = 'Regex word boundary' })
  map('c', '<F5>', my.toggle_case, { desc = "Toggle 'case'", expr = true })
  map('c', '<C-r><C-v>', '<C-r>=luaeval("get_visual_selection(false)")<CR>')

  -- │Help & Messages│
  map('n', '<Leader>m', my.cmd('messages'), { desc = 'Show messages' })

  -- │Miscellaneous Toggles│
  map('n', '<Leader>cq', my.toggle_quotes, { desc = 'Switch quotes in line' })
  map('n', '<Leader>uw', my.cmd('setlocal wrap! wrap?'), { desc = "Toggle 'wrap' option" })
  map('n', '<Leader>un', my.toggle_line_numbers, { desc = "Toggle 'line number' option" })
  map('n', '<C-a>', my.inc_or_swap, { desc = 'Increment or swap boolean' })

  -- │Smart Utilities│
  map('n', '<Leader>%', my.set_cwd, { desc = 'Smart Set cwd' })

  -- │Terminal Mode Enhancements│
  map('t', '<C-Bslash>', '<C-Bslash><C-N>')
  map('t', '<A-r>', my.insert_register_term, { expr = true })
  map('n', '<A-`>', my.cmd('botright 14split term://$SHELL'))

  -- │Yank│
  map({ 'n', 'x' }, 'y', my.pre_yank(false), { expr = true })
  map('n', 'Y', my.pre_yank(true), { expr = true })

  -- │EOL Delimiter Toggle/Replace│
  local delimiter_chars = { ',', ';', '.' }
  for _, char in ipairs(delimiter_chars) do
    map('n', 'd' .. char, function()
      local line = vim.api.nvim_get_current_line()
      local last = line:sub(-1)
      local new = line

      if last == char then
        new = line:sub(1, -2)
      elseif vim.tbl_contains(delimiter_chars, last) then
        new = line:sub(1, -2) .. char
      else
        new = line .. char
      end

      vim.api.nvim_set_current_line(new)
    end, {})
  end
end

--------------------------------------------------------------------------------
-- Setup Readline on InsertEnter and CmdlineEnter Event
--------------------------------------------------------------------------------
-- stylua: ignore
vim.api.nvim_create_autocmd({ 'InsertEnter', 'CmdlineEnter' }, {
  once = true,
  callback = vim.schedule_wrap(function()
    local fn, expr = vim.fn, { expr = true }
    map('c', '<C-a>', '<home>')
    map('i', '<C-a>', '<C-o>^')
    map('c', '<C-b>', '<Left>')
    map('i', '<C-b>', function() return fn.getline('.'):match('^%s*$') and fn.col('.') > #fn.getline('.') and '0<C-D><Esc>kJs' or '<Left>'end, expr)
    map('c', '<C-d>', function() return fn.getcmdpos() > #fn.getcmdline() and '<C-d>' or '<Del>' end, expr)
    map('i', '<C-d>', function() return fn.col('.') > #fn.getline('.') and '<C-d>' or '<Del>' end, expr)
    map('c', '<C-f>', function() return fn.getcmdpos() > #fn.getcmdline() and vim.o.cedit or '<Right>' end, expr)
    map('i', '<C-f>', function() return fn.col('.') > #fn.getline('.') and '<C-f>' or '<Right>' end, expr)
    map('i', '<C-e>', function() return fn.col('.') > #fn.getline('.') or fn.pumvisible() == 1 and '<C-e>' or '<End>' end, expr)
  end),
})

local H = {}
--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

local escape_characters = [[.^$*+?()[]{}|\-]]

-- Move cursor left by count
local function left(count) return string.rep('<left>', count) end

-- Create <Cmd>...<CR> command string
function H.cmd(cmd) return ('<Cmd>%s<CR>'):format(cmd) end

-- taken from https://www.reddit.com/r/neovim/comments/1exnko2/comment/ljaijfl/
function _G.get_visual_selection(escape)
  -- table.concat(vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.')), '\n')
  local text
  if vim.fn.mode():match('[vV]') then
    text = vim.fn.getregion(vim.fn.getpos('.'), vim.fn.getpos('v'), { type = 'v' })[1]
  else
    text = vim.fn.getregion(vim.fn.getpos("'<"), vim.fn.getpos("'>"), { type = 'v' })[1]
  end
  assert(text)
  return escape ~= false and vim.fn.escape(text, escape_characters) or text
end

-- Get a single character
local function getchar()
  local char = vim.fn.getchar()
  if type(char) == 'number' then
    local char_str = vim.fn.nr2char(char)
    return char_str
  end
  return nil
end

-- Substitute ------------------------------------------------------------------
function H.substitute_visual()
  local mode = vim.fn.mode()
  local selection_cmd = '<C-r>=luaeval("get_visual_selection()")<CR>'
  local base_cmd, flags = ':s/', '/gI'

  if mode == 'V' then -- Linewise visual
    return base_cmd .. [[\V/]] .. flags .. left(4)
  elseif mode == '\22' then -- Blockwise visual (CTRL-V)
    return base_cmd .. [[\%V/]] .. flags .. left(4)
  else -- Characterwise visual
    return string.format(':<C-u>%%s/\\v%s/%s%s%s', selection_cmd, selection_cmd, flags, left(3))
  end
end

H.substitute_lsearch = ':%s///gI' .. left(3)
H.substitute_cword = [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI]] .. left(3)
H.substitute_cWORD = [[:%s/\V<C-r><C-a>/<C-r><C-a>/gI]] .. left(3)
H.substitute_lvisual = [[:'<,'>s/\<<C-r><C-w>\>//gI]] .. left(3)

-- Text Editing ----------------------------------------------------------------
function H.join_line() return 'mz' .. vim.v.count1 .. 'J`z' end
function H.safe_paste() return 'pgv"' .. vim.v.register .. 'y' end
function H.insert_register_term() return '<C-\\><C-n>"' .. vim.fn.nr2char(vim.fn.getchar()) .. 'pi' end
function H.nice_block_I() return vim.fn.mode():match('[vV]') and '<C-v>^o^I' or 'I' end
function H.nice_block_A() return vim.fn.mode():match('[vV]') and '<C-v>1o$A' or 'A' end

function H.smart_insert()
  local mode = vim.api.nvim_get_mode().mode
  if mode ~= 'n' then return 'i' end
  local line = vim.api.nvim_get_current_line()
  return vim.trim(line) == '' and '"_cc' or 'i'
end

function H.change_and_repeatable()
  if vim.bo.buftype ~= '' then return end
  if vim.fn.mode():match('[n]') then
    return '*N"_cgn'
  elseif vim.fn.mode():match('[v]') then
    local text = get_visual_selection(false)
    vim.fn.setreg('/', '\\V' .. text)
    return '<Esc>"_cgn'
  end
end

function H.register()
  local char_1 = getchar()
  if char_1 then
    local char_2 = getchar()
    return string.format('"%s%s', char_1, char_2)
  end
end

function H.macro_word(record)
  return function()
    if vim.fn.getreg('z') ~= '' then return 'n@z' end
    if record then return '*Nqz' end
    return vim.fn.reg_recording() == 'z' and 'q' or '*Nqz'
  end
end

function H.inc_or_swap()
  local toggle_map = {
    ['true'] = 'false',
    ['false'] = 'true',
    ['on'] = 'off',
    ['off'] = 'on',
    ['and'] = 'or',
    ['or'] = 'and',
    ['=='] = '!=',
    ['!='] = '==',
    ['>'] = '<',
    ['<'] = '>',
    ['>='] = '<=',
    ['<='] = '>=',
  }

  local current_word = vim.fn.expand('<cword>')
  local replacement = toggle_map[current_word]

  if replacement then
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    vim.cmd.normal({ '"_ciw' .. replacement, bang = true })
    vim.api.nvim_win_set_cursor(0, cursor_pos)
  else
    vim.cmd.execute('"normal! ' .. vim.v.count1 .. '\\<C-a>"')
  end
end

function H.toggle_quotes()
  local line = vim.api.nvim_get_current_line()
  local updatedLine = line:gsub('["\']', function(q) return (q == [["]] and [[']] or [["]]) end)
  vim.api.nvim_set_current_line(updatedLine)
end

local cache_copy_line = nil

NH.copy_line = function(cache)
  if not cache then
    cache_copy_line = nil
    vim.go.operatorfunc = 'v:lua.NH.callback_copy_line'
    return 'g@l'
  end
  if cache_copy_line then vim.cmd(cache_copy_line) end
end

NH.callback_copy_line = function(mode)
  if mode == 'char' then
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    if not cache_copy_line then cache_copy_line = 't' .. line end
    NH.copy_line(cache_copy_line)
    vim.api.nvim_win_set_cursor(0, { line + 1, col })
  else
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local start_pos = vim.fn.getpos("'<")[2]
    local end_pos = vim.fn.getpos("'>")[2]

    local top = math.min(start_pos, end_pos)
    local bottom = math.max(start_pos, end_pos)
    local diff = bottom - top

    if not cache_copy_line then cache_copy_line = top .. ',' .. bottom .. 't+' .. diff end
    NH.copy_line(cache_copy_line)
    vim.api.nvim_win_set_cursor(0, { line + 1 + diff, col })
  end
end

-- Toggle Ui -------------------------------------------------------------------
do
  local LINE_NUMBERS = {
    ff = '  nu   rnu',
    ft = '  nu nornu',
    tf = 'nonu nornu',
    tt = '  nu nornu',
  }
  function H.toggle_line_numbers()
    local n = vim.o.number and 't' or 'f'
    local r = vim.o.relativenumber and 't' or 'f'
    local cmd = LINE_NUMBERS[n .. r]
    vim.api.nvim_command('set ' .. cmd)
    print(cmd)
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
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    local word = vim.fn.expand('<cword>')
    local start = vim.fn.matchstrpos(vim.fn.getline('.'), '\\k*\\%' .. (col + 1) .. 'c\\k*')[2]

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

    vim.api.nvim_buf_set_text(0, line - 1, start, line - 1, start + #word, { result })
  end
end

-- Pre yank --------------------------------------------------------------------
-- Cursor restored in autocmd Hl yank
function H.pre_yank(normal_only)
  return function()
    vim.b.cursor_pre_yank = vim.api.nvim_win_get_cursor(0)
    return normal_only and 'y_' or 'y'
  end
end

-- Set cwd ---------------------------------------------------------------------
function H.set_cwd()
  local file_dir = vim.fn.expand('%:h')
  vim.system({ 'git', 'rev-parse', '--show-toplevel' }, { text = true, cwd = file_dir }, function(result)
    if result.code == 0 and result.stdout then
      local git_root = result.stdout:gsub('%s+$', '')
      vim.schedule(function()
        vim.cmd('cd ' .. vim.fn.fnameescape(git_root))
        vim.notify(('Working directory set to Git root: %s'):format(git_root), vim.log.levels.INFO, {})
      end)
    else
      vim.schedule(function()
        vim.cmd('cd ' .. vim.fn.fnameescape(file_dir))
        vim.notify(('Git root not found. Using current file dir: %s'):format(file_dir), vim.log.levels.WARN, {})
      end)
    end
  end)
end

-- Remap q, --------------------------------------------------------------------
function H.qkey()
  local rec = vim.fn.reg_recording()
  if rec ~= '' then return 'q' end
  local char = getchar()
  if char == ',' then
    return 'q:'
  else
    return 'q' .. char
  end
end

-- Remap q, --------------------------------------------------------------------
function H.gf()
  local mode = vim.fn.mode()
  if mode:match('[V\22]') then
    return '<Esc>/\\%V' -- code untuk V atau CTRL-V (block visual)
  else
    return 'gf'
  end
end

-- Smart Home/End Key ----------------------------------------------------------
function H.smart_home()
  local col = vim.fn.col('.') - 1
  local line = vim.fn.getline('.')
  local str_before_cursor = line:sub(1, col)

  local wrap_prefix = vim.wo.wrap and 'g' or ''

  if str_before_cursor:match('^%s*$') then
    return wrap_prefix .. '0'
  else
    return wrap_prefix .. '^'
  end
end

function H.smart_end() return vim.wo.wrap and 'g$' or '$' end

-- Utils Operator Function -----------------------------------------------------
local function get_mark(mark)
  local pos = vim.api.nvim_buf_get_mark(0, mark)
  if pos[1] == 0 then return nil end
  pos[2] = pos[2] + 1
  return pos
end

local function get_str(mode, first_pos, last_pos)
  -- different types of operator funcs need different ways of getting lines
  if mode == 'line' then
    return vim.api.nvim_buf_get_lines(0, first_pos[1] - 1, last_pos[1], false)
  elseif mode == 'char' then
    return vim.api.nvim_buf_get_text(
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
  NH._opfunc = create_opfunc(callback, allow_multiline)
  vim.go.operatorfunc = 'v:lua.NH._opfunc'
  return 'g@'
end

function H.substitute_opfunc()
  local mode = vim.fn.mode()
  local base_cmd, flags = ':s/', '/gI'

  if mode == 'V' then -- Visual line mode
    return base_cmd .. [[\V/]] .. flags .. left(4)
  elseif mode == '\22' then -- Visual block mode (Ctrl-V)
    return base_cmd .. [[\%V/]] .. flags .. left(4)
  else -- Visual charwise atau operatorfunc charwise
    return H.opfunc(function(result)
      local left = vim.keycode('<Left>')
      local escaped = vim.fn.escape(result, escape_characters)
      local command = ':%s/\\v' .. escaped .. '/' .. result .. '/gI'
      vim.api.nvim_feedkeys(command .. string.rep(left, 3), 'n', true)
    end)
  end
end

--------------------------------------------------------------------------------
-- Initialize
--------------------------------------------------------------------------------
vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = vim.schedule_wrap(function() setup(H) end),
})

--------------------------------------------------------------------------------
