-- _________________________________________
-- \_ _/ ____| ____| ___ \ ____| ___ \  ___/
--  | | |____| ____| ___ < ____| __  / |__ \
-- /___\_____|_____|_____/_____|_| \_\_____/
--
-- File:       iceberg.lua
-- Modified:   Sat May 31 12:51:27 AM WIB 2025
-- License:    MIT
-- Desc:       Port from vimscript to lua by Huda

if vim.g.colors_name ~= nil then vim.cmd('highlight clear') end
vim.g.colors_name = 'iceberg'

-- Highlight groups
local hi = vim.api.nvim_set_hl

if vim.o.background == 'light' then
  hi(0, 'Normal', { bg = '#e8e9ec', fg = '#33374c' })
  hi(0, 'ColorColumn', { bg = '#dcdfe7', fg = nil })
  hi(0, 'CursorColumn', { bg = '#dcdfe7', fg = nil })
  hi(0, 'CursorLine', { bg = '#dcdfe7', fg = nil })
  hi(0, 'Comment', { fg = '#8389a3' })
  hi(0, 'Conceal', { bg = '#e8e9ec', fg = '#8389a3' })
  hi(0, 'Constant', { fg = '#7759b4' })
  hi(0, 'Cursor', { bg = '#33374c', fg = '#e8e9ec' })
  hi(0, 'CursorLineNr', { bg = '#cad0de', fg = '#576a9e' })
  hi(0, 'Delimiter', { fg = '#33374c' })
  hi(0, 'DiffAdd', { bg = '#d4dbd1', fg = '#475946' })
  hi(0, 'DiffChange', { bg = '#ced9e1', fg = '#375570' })
  hi(0, 'DiffDelete', { bg = '#e3d2da', fg = '#70415e' })
  hi(0, 'DiffText', { bg = '#acc5d3', fg = '#33374c' })
  hi(0, 'Directory', { fg = '#3f83a6' })
  hi(0, 'Error', { bg = '#e8e9ec', fg = '#cc517a' })
  hi(0, 'ErrorMsg', { bg = '#e8e9ec', fg = '#cc517a' })
  hi(0, 'WarningMsg', { bg = '#e8e9ec', fg = '#cc517a' })
  hi(0, 'EndOfBuffer', { fg = '#cbcfda' })
  hi(0, 'NonText', { fg = '#cbcfda' })
  hi(0, 'Whitespace', { fg = '#cbcfda' })
  hi(0, 'Folded', { bg = '#dcdfe7', fg = '#788098' })
  hi(0, 'FoldColumn', { bg = '#dcdfe7', fg = '#9fa7bd' })
  hi(0, 'Function', { fg = '#2d539e' })
  hi(0, 'Identifier', { fg = '#3f83a6' })
  hi(0, 'Ignore', { bg = nil, fg = nil })
  hi(0, 'Include', { fg = '#2d539e' })
  hi(0, 'IncSearch', { reverse = true, fg = nil })
  hi(0, 'LineNr', { bg = '#dcdfe7', fg = '#9fa7bd' })
  hi(0, 'MatchParen', { bg = '#bec0c9', fg = '#33374c' })
  hi(0, 'ModeMsg', { fg = '#8389a3' })
  hi(0, 'MoreMsg', { fg = '#668e3d' })
  hi(0, 'Operator', { fg = '#2d539e' })
  hi(0, 'Pmenu', { bg = '#cad0de', fg = '#33374c' })
  hi(0, 'PmenuSbar', { bg = '#cad0de', fg = nil })
  hi(0, 'PmenuSel', { bg = '#a7b2cd', fg = '#33374c' })
  hi(0, 'PmenuThumb', { bg = '#33374c', fg = nil })
  hi(0, 'PreProc', { fg = '#668e3d' })
  hi(0, 'Question', { fg = '#668e3d' })
  hi(0, 'QuickFixLine', { bg = '#c9cdd7', fg = '#33374c' })
  hi(0, 'Search', { bg = '#eac6ad', fg = '#85512c' })
  -- hi(0, 'SignColumn', { bg = '#dcdfe7', fg = '#9fa7bd' })
  hi(0, 'Special', { fg = '#668e3d' })
  hi(0, 'SpecialKey', { fg = '#a5b0d3' })
  hi(0, 'SpellBad', { undercurl = true, fg = nil, sp = '#cc517a' })
  hi(0, 'SpellCap', { undercurl = true, fg = nil, sp = '#2d539e' })
  hi(0, 'SpellLocal', { undercurl = true, fg = nil, sp = '#3f83a6' })
  hi(0, 'SpellRare', { undercurl = true, fg = nil, sp = '#7759b4' })
  hi(0, 'Statement', { fg = '#2d539e' })
  hi(0, 'StatusLine', { reverse = true, bg = '#e8e9ec', fg = '#757ca3' })
  hi(0, 'StatusLineTerm', { reverse = true, bg = '#e8e9ec', fg = '#757ca3' })
  hi(0, 'StatusLineNC', { reverse = true, bg = '#8b98b6', fg = '#cad0de' })
  hi(0, 'StatusLineTermNC', { reverse = true, bg = '#8b98b6', fg = '#cad0de' })
  hi(0, 'StorageClass', { fg = '#2d539e' })
  hi(0, 'String', { fg = '#3f83a6' })
  hi(0, 'Structure', { fg = '#2d539e' })
  hi(0, 'TabLine', { bg = '#cad0de', fg = '#8b98b6' })
  hi(0, 'TabLineFill', { reverse = true, bg = '#8b98b6', fg = '#cad0de' })
  hi(0, 'TabLineSel', { link = 'StatusLine' })
  hi(0, 'TermCursorNC', { bg = '#8389a3', fg = '#e8e9ec' })
  hi(0, 'Title', { fg = '#c57339' })
  hi(0, 'Todo', { bg = '#d4dbd1', fg = '#668e3d' })
  hi(0, 'Type', { fg = '#2d539e' })
  hi(0, 'Underlined', { underline = true, fg = '#2d539e' })
  hi(0, 'VertSplit', { bg = '#cad0de', fg = '#cad0de' })
  hi(0, 'Visual', { bg = '#c9cdd7', fg = nil })
  hi(0, 'VisualNOS', { bg = '#c9cdd7', fg = nil })
  hi(0, 'WildMenu', { bg = '#32364c', fg = '#e8e9ec' })
  hi(0, 'icebergNormalFg', { fg = '#33374c' })
  hi(0, 'diffAdded', { fg = '#668e3d' })
  hi(0, 'diffRemoved', { fg = '#cc517a' })
  hi(0, 'TSFunction', { fg = '#505695' })
  hi(0, 'TSFunctionBuiltin', { fg = '#505695' })
  hi(0, 'TSFunctionMacro', { fg = '#505695' })
  hi(0, 'TSMethod', { fg = '#505695' })
  hi(0, 'TSURI', { underline = true, fg = '#3f83a6' })
  hi(0, 'DiagnosticUnderlineInfo', { underline = true, sp = '#3f83a6' })
  hi(0, 'DiagnosticInfo', { fg = '#3f83a6' })
  hi(0, 'DiagnosticSignInfo', { bg = '#dcdfe7', fg = '#3f83a6' })
  hi(0, 'DiagnosticUnderlineHint', { underline = true, sp = '#8389a3' })
  hi(0, 'DiagnosticHint', { fg = '#8389a3' })
  hi(0, 'DiagnosticSignHint', { bg = '#dcdfe7', fg = '#8389a3' })
  hi(0, 'DiagnosticUnderlineWarn', { underline = true, sp = '#c57339' })
  hi(0, 'DiagnosticWarn', { fg = '#c57339' })
  hi(0, 'DiagnosticSignWarn', { bg = '#dcdfe7', fg = '#c57339' })
  hi(0, 'DiagnosticUnderlineError', { underline = true, sp = '#cc517a' })
  hi(0, 'DiagnosticError', { fg = '#cc517a' })
  hi(0, 'DiagnosticSignError', { bg = '#dcdfe7', fg = '#cc517a' })
  hi(0, 'DiagnosticFloatingHint', { bg = '#cad0de', fg = '#33374c' })

  vim.g.terminal_color_0 = '#dcdfe7'
  vim.g.terminal_color_1 = '#cc517a'
  vim.g.terminal_color_2 = '#668e3d'
  vim.g.terminal_color_3 = '#c57339'
  vim.g.terminal_color_4 = '#2d539e'
  vim.g.terminal_color_5 = '#7759b4'
  vim.g.terminal_color_6 = '#3f83a6'
  vim.g.terminal_color_7 = '#33374c'
  vim.g.terminal_color_8 = '#8389a3'
  vim.g.terminal_color_9 = '#cc3768'
  vim.g.terminal_color_10 = '#598030'
  vim.g.terminal_color_11 = '#b6662d'
  vim.g.terminal_color_12 = '#22478e'
  vim.g.terminal_color_13 = '#6845ad'
  vim.g.terminal_color_14 = '#327698'
  vim.g.terminal_color_15 = '#262a3f'
else
  hi(0, 'Normal', { bg = '#161821', fg = '#c6c8d1' })
  hi(0, 'ColorColumn', { bg = '#1e2132', fg = nil })
  hi(0, 'CursorColumn', { bg = '#1e2132', fg = nil })
  hi(0, 'CursorLine', { bg = '#1e2132', fg = nil })
  hi(0, 'Comment', { fg = '#6b7089' })
  hi(0, 'Conceal', { bg = '#161821', fg = '#6b7089' })
  hi(0, 'Constant', { fg = '#a093c7' })
  hi(0, 'Cursor', { bg = '#c6c8d1', fg = '#161821' })
  hi(0, 'CursorLineNr', { bg = '#2a3158', fg = '#cdd1e6' })
  hi(0, 'Delimiter', { fg = '#c6c8d1' })
  hi(0, 'DiffAdd', { bg = '#45493e', fg = '#c0c5b9' })
  hi(0, 'DiffChange', { bg = '#384851', fg = '#b3c3cc' })
  hi(0, 'DiffDelete', { bg = '#53343b', fg = '#ceb0b6' })
  hi(0, 'DiffText', { bg = '#5b7881', fg = '#c6c8d1' })
  hi(0, 'Directory', { fg = '#89b8c2' })
  hi(0, 'Error', { bg = '#e27878', fg = '#161821' })
  hi(0, 'ErrorMsg', { link = 'Error' })
  hi(0, 'WarningMsg', { fg = '#e2a478' })
  hi(0, 'EndOfBuffer', { fg = '#242940' })
  hi(0, 'NonText', { fg = '#242940' })
  hi(0, 'Whitespace', { fg = '#242940' })
  hi(0, 'Folded', { bg = '#1e2132', fg = '#686f9a' })
  hi(0, 'FoldColumn', { bg = '#1e2132', fg = '#444b71' })
  hi(0, 'Function', { fg = '#84a0c6' })
  hi(0, 'Identifier', { fg = '#89b8c2' })
  hi(0, 'Ignore', { bg = nil, fg = nil })
  hi(0, 'Include', { fg = '#84a0c6' })
  hi(0, 'IncSearch', { reverse = true, fg = nil })
  hi(0, 'LineNr', { bg = '#161821', fg = '#6b7089' })
  hi(0, 'MatchParen', { bg = '#3e445e', fg = '#ffffff' })
  hi(0, 'ModeMsg', { fg = '#6b7089' })
  hi(0, 'MoreMsg', { fg = '#b4be82' })
  hi(0, 'Operator', { fg = '#84a0c6' })
  hi(0, 'Pmenu', { bg = '#3d425b', fg = '#c6c8d1' })
  hi(0, 'PmenuSbar', { bg = '#3d425b', fg = nil })
  hi(0, 'PmenuSel', { bg = '#5b6389', fg = '#eff0f4' })
  hi(0, 'PmenuThumb', { bg = '#c6c8d1', fg = nil })
  hi(0, 'PreProc', { fg = '#b4be82' })
  hi(0, 'Question', { fg = '#b4be82' })
  hi(0, 'QuickFixLine', { bg = '#272c42', fg = '#c6c8d1' })
  hi(0, 'Search', { bg = '#e4aa80', fg = '#392313' })
  -- hi(0, 'SignColumn', { bg = '#1e2132', fg = '#444b71' })
  hi(0, 'Special', { fg = '#b4be82' })
  hi(0, 'SpecialKey', { fg = '#515e97' })
  hi(0, 'SpellBad', { undercurl = true, fg = nil, sp = '#e27878' })
  hi(0, 'SpellCap', { undercurl = true, fg = nil, sp = '#84a0c6' })
  hi(0, 'SpellLocal', { undercurl = true, fg = nil, sp = '#89b8c2' })
  hi(0, 'SpellRare', { undercurl = true, fg = nil, sp = '#a093c7' })
  hi(0, 'Statement', { fg = '#84a0c6' })
  hi(0, 'StatusLine', { reverse = true, bg = '#17171b', fg = '#818596' })
  hi(0, 'StatusLineTerm', { reverse = true, bg = '#17171b', fg = '#818596' })
  hi(0, 'StatusLineNC', { reverse = true, bg = '#3e445e', fg = '#0f1117' })
  hi(0, 'StatusLineTermNC', { reverse = true, bg = '#3e445e', fg = '#0f1117' })
  hi(0, 'StorageClass', { fg = '#84a0c6' })
  hi(0, 'String', { fg = '#89b8c2' })
  hi(0, 'Structure', { fg = '#84a0c6' })
  hi(0, 'TabLine', { bg = '#161821', fg = '#c6c8d1' })
  hi(0, 'TabLineFill', { bg = '#161821', fg = '#a093c7' })
  hi(0, 'TabLineSel', { link = 'StatusLine' })
  hi(0, 'TermCursorNC', { bg = '#6b7089', fg = '#161821' })
  hi(0, 'Title', { fg = '#e2a478' })
  hi(0, 'Todo', { bg = '#45493e', fg = '#b4be82' })
  hi(0, 'Type', { fg = '#84a0c6' })
  hi(0, 'Underlined', { underline = true, fg = '#84a0c6' })
  hi(0, 'VertSplit', { bg = '#0f1117', fg = '#0f1117' })
  hi(0, 'Visual', { bg = '#272c42', fg = nil })
  hi(0, 'VisualNOS', { bg = '#272c42', fg = nil })
  hi(0, 'WildMenu', { bg = '#d4d5db', fg = '#17171b' })
  hi(0, 'icebergNormalFg', { fg = '#c6c8d1' })
  hi(0, 'diffAdded', { fg = '#b4be82' })
  hi(0, 'diffRemoved', { fg = '#e27878' })
  hi(0, 'TSFunction', { fg = '#a3adcb' })
  hi(0, 'TSFunctionBuiltin', { fg = '#a3adcb' })
  hi(0, 'TSFunctionMacro', { fg = '#a3adcb' })
  hi(0, 'TSMethod', { fg = '#a3adcb' })
  hi(0, 'TSURI', { underline = true, fg = '#89b8c2' })
  hi(0, 'DiagnosticUnderlineInfo', { underline = true, sp = '#89b8c2' })
  hi(0, 'DiagnosticInfo', { fg = '#89b8c2' })
  hi(0, 'DiagnosticSignInfo', { bg = '#1e2132', fg = '#89b8c2' })
  hi(0, 'DiagnosticUnderlineHint', { underline = true, sp = '#6b7089' })
  hi(0, 'DiagnosticHint', { fg = '#6b7089' })
  hi(0, 'DiagnosticSignHint', { bg = '#1e2132', fg = '#6b7089' })
  hi(0, 'DiagnosticUnderlineWarn', { underline = true, sp = '#e2a478' })
  hi(0, 'DiagnosticWarn', { fg = '#e2a478' })
  hi(0, 'DiagnosticSignWarn', { bg = '#1e2132', fg = '#e2a478' })
  hi(0, 'DiagnosticUnderlineError', { underline = true, sp = '#e27878' })
  hi(0, 'DiagnosticError', { fg = '#e27878', bg = nil })
  hi(0, 'DiagnosticSignError', { bg = '#1e2132', fg = '#e27878' })
  -- hi(0, 'DiagnosticFloatingHint', { bg = '#3d425b', fg = '#c6c8d1' })

  vim.g.terminal_color_0 = '#1e2132'
  vim.g.terminal_color_1 = '#e27878'
  vim.g.terminal_color_2 = '#b4be82'
  vim.g.terminal_color_3 = '#e2a478'
  vim.g.terminal_color_4 = '#84a0c6'
  vim.g.terminal_color_5 = '#a093c7'
  vim.g.terminal_color_6 = '#89b8c2'
  vim.g.terminal_color_7 = '#c6c8d1'
  vim.g.terminal_color_8 = '#6b7089'
  vim.g.terminal_color_9 = '#e98989'
  vim.g.terminal_color_10 = '#c0ca8e'
  vim.g.terminal_color_11 = '#e9b189'
  vim.g.terminal_color_12 = '#91acd1'
  vim.g.terminal_color_13 = '#ada0d3'
  vim.g.terminal_color_14 = '#95c4ce'
  vim.g.terminal_color_15 = '#d2d4de'
end

hi(0, 'NormalFloat', { link = 'Normal' })
hi(0, 'FloatBorder', { fg = '#33374c', bg = nil })
hi(0, 'DiagnosticFloatingHint', { link = 'Normal' })
hi(0, 'PMenuExtra', { link = 'PMenu' })
hi(0, 'TermCursor', { link = 'Cursor' })
hi(0, 'markdownBold', { link = 'Special' })
hi(0, 'markdownCode', { link = 'String' })
hi(0, 'markdownCodeDelimiter', { link = 'String' })
hi(0, 'markdownHeadingDelimiter', { link = 'Comment' })
hi(0, 'markdownRule', { link = 'Comment' })
hi(0, 'SpecialKey', { link = 'Whitespace' })
hi(0, 'MiniJump2dSpot', { bg = '#c0ca8e', fg = '#1e2132', bold = true })
hi(0, 'MiniJump2dSpotAhead', { bg = '#c0ca8e', fg = '#1e2132', bold = true })
hi(0, 'BufferJump', { fg = '#e4aa80', bg = nil, bold = true })
hi(0, 'MiniJump2dSpotUnique', { link = 'MiniJump2dSpot' })
hi(0, 'SignatureMarkLine', { link = 'StatusLine' })
