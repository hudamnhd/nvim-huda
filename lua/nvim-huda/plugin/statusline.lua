--------------------------------------------------------------------------------
-- Statusline
--------------------------------------------------------------------------------

-- Map Neovim mode ke nama human-readable
local mode_alias = {
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

-- Cache state
local branch = ''
local diagnostic = ''
local diff_info = ''

-- Components ------------------------------------------------------------------
local function get_mode()
  local mode = vim.api.nvim_get_mode().mode
  local label = mode_alias[mode] or mode_alias[mode:sub(1, 1)] or 'UNK'
  return label:sub(1, 3):upper()
end

local function get_diff(file)
  local relpath = vim.fn.fnamemodify(file, ':.')
  local cmd = 'git diff --no-color --unified=0 -- ' .. vim.fn.shellescape(relpath)
  local output = vim.fn.systemlist(cmd)

  if vim.v.shell_error ~= 0 then return '' end

  local added, removed, changed = 0, 0, 0
  for _, line in ipairs(output) do
    local d1, dc, a1, ac = line:match('^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@')
    if d1 then
      dc, ac = tonumber(dc) or 1, tonumber(ac) or 1
      if dc > 0 and ac > 0 then
        changed = changed + math.min(dc, ac)
        if dc > ac then
          removed = removed + (dc - ac)
        elseif ac > dc then
          added = added + (ac - dc)
        end
      elseif dc > 0 then
        removed = removed + dc
      elseif ac > 0 then
        added = added + ac
      end
    end
  end

  local segments = {}
  if added > 0 then table.insert(segments, '+' .. added) end
  if changed > 0 then table.insert(segments, '~' .. changed) end
  if removed > 0 then table.insert(segments, '-' .. removed) end

  return #segments > 0 and (' %s '):format(table.concat(segments, ' ')) or ''
end

local function get_branch()
  local output = vim.fn.system('git rev-parse --abbrev-ref HEAD 2>/dev/null')
  local name = output:gsub('\n', '')
  return name ~= '' and not name:match('fatal') and '[' .. name .. ']' or ''
end

local function get_diagnostic()
  if not vim.diagnostic.is_enabled({ bufnr = 0 }) or #vim.lsp.get_clients({ bufnr = 0 }) == 0 then return '' end

  local has_icons = vim.fn.exists('+termguicolors') == 1
  local icons = has_icons and { '󰅚 ', '󰀪 ', '󰋽 ', '󰌶 ' } or { 'E', 'W', 'I', 'H' }

  local parts = {}
  for i = 1, 4 do
    local count = #vim.diagnostic.get(0, { severity = i })
    if count > 0 then table.insert(parts, string.format('%s%d', icons[i], count)) end
  end

  return #parts > 0 and ' ' .. table.concat(parts, ' ') .. ' ' or ''
end

-- Statusline format -----------------------------------------------------------
local components = {
  ' %{v:lua.NH.stl.get_mode()}%*',
  ":%{(&modified&&&readonly?'%*':(&modified?'**':(&readonly?'%%':'--')))}",
  ' %P (%#StatusLineNr#%l%*,%02c) ',
  '%t',
  ' %{v:lua.NH.stl.get_branch()}%*',
  ' %{v:lua.NH.stl.get_diff()}%*',
  ' %{v:lua.NH.stl.get_diagnostic()}%*',
  ' %=',
  '%y ',
  '%{&ff} ',
  '%{&fenc?&fenc:&enc} ',
}


_G.NH.stl = {
  get_mode = get_mode,
  get_branch = function() return branch end,
  get_diff = function() return diff_info end,
  get_diagnostic = function() return diagnostic end,
  statusline = function() return table.concat(components) end,
}

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = vim.schedule_wrap(function()
    branch = get_branch()
    vim.opt.statusline = '%{%v:lua.NH.stl.statusline()%}'
    vim.api.nvim_set_hl(0, 'StatusLineNr', { bold = true })
  end),
})

vim.api.nvim_create_autocmd({ 'BufEnter' }, {
  callback = function(ctx)
    local file = vim.uv.fs_realpath(ctx.file or '')
    if not file or vim.fn.isdirectory(file) == 1 then return end
    vim.defer_fn(function() diff_info = get_diff(file) end, 500)
  end,
})

vim.api.nvim_create_autocmd({ 'BufEnter', 'LspAttach', 'DiagnosticChanged' }, {
  callback = function(ctx)
    local file = vim.uv.fs_realpath(ctx.file or '')
    if not file or vim.fn.isdirectory(file) == 1 then return end
    vim.defer_fn(function() diagnostic = get_diagnostic() end, 500)
  end,
})

--------------------------------------------------------------------------------
