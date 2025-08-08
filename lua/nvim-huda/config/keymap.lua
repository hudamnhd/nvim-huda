--------------------------------------------------------------------------------
-- Keymap
--------------------------------------------------------------------------------
local map = vim.keymap.set

-- │Leader Key│
vim.g.mapleader = vim.keycode('<space>')
vim.g.maplocalleader = vim.keycode('<space>')

local setup = function(my)
  -- │Disabled Keys│
  map('n', '<C-r>', '<Nop>')
  map({ 'n', 'x' }, 's', '<Nop>')
  map({ 'n', 'x' }, '<Space>', '<Nop>')

  -- │Blackhole keys│
  map('n', 'd', '"_d')
  map('n', 'c', '"_c')
  map({ 'n', 'x' }, 'x', '"_x')

  -- |Undo-break point|
  map('i', ',', ',<C-g>u')
  map('i', ';', ';<C-g>u')
  map('i', '.', '.<C-g>u')

  -- │Swap Command-Line│
  map({ 'n', 'x' }, ',', ':')
  map({ 'n', 'x' }, ':', ',')

  -- │Buffer delete│
  map('n', '<Leader>q', my.cmd('bd'), { desc = 'Delete buffer' })

  -- │Window Navigation│
  map('n', '<A-w>', '<C-w>w', { desc = 'Next window' })
  map('t', '<A-w>', '<C-Bslash><C-n><C-w>w', { desc = 'Next window (terminal)' })

  -- │Navigation│
  map({ 'n', 'x' }, '<C-z>', '%', { desc = 'Jump to matching bracket' })
  map({ 'n', 'x' }, '<C-h>', '^', { desc = 'Move to start of line' })
  map({ 'n', 'x' }, '<C-l>', 'g_', { desc = 'Move to end of line' })
  map({ 'n', 'x' }, 'j', [[(v:count > 5 ? "m'" . v:count : "") . 'j']], { desc = 'Line up', expr = true })
  map({ 'n', 'x' }, 'k', [[(v:count > 5 ? "m'" . v:count : "") . 'k']], { desc = 'Line down', expr = true })

  -- │Enhancements│
  map('v', '>', '>gv')
  map('v', '<', '<gv')
  map('v', 'I', my.nice_block_I, { expr = true })
  map('v', 'A', my.nice_block_A, { expr = true })
  map('n', 'i', my.smart_insert, { expr = true })

  -- │Line Manipulation│
  map({ 'n', 'x' }, 'gm', my.duplicate_line, { desc = 'Duplicate line', expr = true })
  map('n', 'J', my.join_line, { desc = 'Join lines and keep cursor', expr = true })

  -- │Clipboard & Yank / Paste│
  map('x', 'p', my.safe_paste, { desc = 'Paste without overwriting register', expr = true })
  map('n', 'gV', '`[v`]', { desc = 'Visual select last yank/paste' })
  map({ 'n', 'x' }, 'gy', '"+y', { desc = 'Yank to system clipboard' })
  map({ 'n', 'x' }, 'gp', '"+p', { desc = 'Paste from system clipboard' })
  map({ 'n', 'x' }, '<Leader>r', my.register, { desc = 'register', expr = true })

  -- │Case Transformation│
  map('n', 'cu', my.switch_case('upper'))
  map('n', 'cl', my.switch_case('lower'))
  map('n', 'ct', my.switch_case('title'))
  map('n', 'cn', my.switch_case('snake'))
  map('n', 'cc', my.switch_case('camel'))

  -- │Change text│
  map({ 'n', 'x' }, '<BS>', my.change_and_repeatable, { desc = 'Change word/selection', expr = true })

  -- │Macro Utilities│
  map('n', '<F7>', my.macro_word(true), { desc = 'Start macro for word', expr = true })
  map('n', '<F8>', my.macro_word(false), { desc = 'End/replay macro', expr = true })

  -- │Substitute│
  map('n', '<Leader>sv', my.sub_last_visual, { desc = 'Substitute last visual' })
  map('n', '<Leader>sr', my.sub_last_search, { desc = 'Substitute last search' })
  map({ 'n', 'x' }, '<Leader>sk', my.sub_normal_visual, { desc = 'Substitute word/selection', expr = true })

  -- │Cmdline / Search / Regex│
  map('x', 'g/', '<Esc>/\\%V', { desc = 'Search inside visual selection' })
  map('c', '%%', [[getcmdtype() == ':' ? expand('%:h') . '/' : '%%']], { expr = true })
  map('c', '<F1>', [[\(.*\)]], { desc = 'Regex capture all' })
  map('c', '<F2>', [[.\{-}]], { desc = 'Regex fuzzy match' })
  map('c', '<F3>', [[\<\><left><left>]], { desc = 'Regex word boundary' })
  map('c', '<C-r><C-s>', '<C-r>=luaeval("get_visual_selection(false)")<CR>')
  map('c', '<C-g><C-c>', my.toggle_case, { desc = "Toggle 'case'", expr = true })

  -- │Help & Messages│
  map('n', '<Leader>m', my.cmd('messages'), { desc = 'Show messages' })

  -- │Miscellaneous Toggles│
  map('n', '<C-S-Q>', my.switch_quote, { desc = 'Switch quotes in line' })
  map('n', '<C-S-W>', my.cmd('setlocal wrap! wrap?'), { desc = "Toggle 'wrap' option" })
  map('n', '<C-S-N>', my.toggle_line_numbers, { desc = "Toggle 'line number' option" })
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
    map('c', '<c-a>', '<home>')
    map('i', '<c-a>', '<c-o>^')
    map('c', '<c-b>', '<left>')
    map('i', '<c-b>', function() return fn.getline('.'):match('^%s*$') and fn.col('.') > #fn.getline('.') and '0<C-D><Esc>kJs' or '<Left>'end, expr)
    map('c', '<c-d>', function() return fn.getcmdpos() > #fn.getcmdline() and '<C-d>' or '<Del>' end, expr)
    map('i', '<c-d>', function() return fn.col('.') > #fn.getline('.') and '<C-d>' or '<Del>' end, expr)
    map('c', '<c-f>', function() return fn.getcmdpos() > #fn.getcmdline() and vim.o.cedit or '<Right>' end, expr)
    map('i', '<c-f>', function() return fn.col('.') > #fn.getline('.') and '<C-f>' or '<Right>' end, expr)
    map('i', '<c-e>', function() return fn.col('.') > #fn.getline('.') or fn.pumvisible() == 1 and '<C-e>' or '<End>' end, expr)
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

--------------------------------------------------------------------------------
-- Substitutions
--------------------------------------------------------------------------------

function H.sub_normal_visual()
  if vim.fn.mode():match('[n]') then
    return [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI]] .. left(3)
  elseif vim.fn.mode():match('[V]') then
    return ':s/\\V//gI' .. left(4)
  else
    local text = get_visual_selection()
    return string.format('%s/\\v%s/%s/gI%s', ':<C-u>%s', text, text, left(3))
  end
end

H.sub_last_search = ':%s///gI' .. left(3)
H.sub_last_visual = [[:'<,'>s/\<<C-r><C-w>\>//gI]] .. left(3)

--------------------------------------------------------------------------------
-- Text Editing
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Toggle Utilities
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Word Swapping / Toggling
--------------------------------------------------------------------------------

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

function H.switch_quote()
  local line = vim.api.nvim_get_current_line()
  local updatedLine = line:gsub('["\']', function(q) return (q == [["]] and [[']] or [["]]) end)
  vim.api.nvim_set_current_line(updatedLine)
end

--------------------------------------------------------------------------------
-- Case Conversions
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Macros & Yank Helpers
--------------------------------------------------------------------------------

function H.macro_word(record)
  if vim.fn.getreg('z') ~= '' then return 'n@z' end
  return function()
    if record then return '*Nqz' end
    return vim.fn.reg_recording() == 'z' and 'q' or '*Nqz'
  end
end

-- Cursor restored in autocmd Hl yank
function H.pre_yank(normal_only)
  return function()
    vim.b.cursor_pre_yank = vim.api.nvim_win_get_cursor(0)
    return normal_only and 'y_' or 'y'
  end
end

--------------------------------------------------------------------------------
-- Set cwd
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Duplicating
--------------------------------------------------------------------------------

function H.duplicate_line()
  local mode = vim.fn.mode()
  if mode == 'n' then
    return H.cmd('t.')
  else
    return ':t+' .. math.abs(vim.fn.line('.') - vim.fn.line('v')) .. '<Cr>'
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
