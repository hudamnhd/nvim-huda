local M = {}

-- Setup global namespace
_G.NH = _G.NH or {}

-- Pretty print helper (globally accessible)
function _G.P(...)
  local args = { ... }
  for i = 1, select('#', ...) do
    args[i] = vim.inspect(args[i])
  end
  print(table.concat(args, ', '))
  return ...
end

-- Determine plugin root directory
local FILE_PATH = debug.getinfo(1, 'S').source:sub(2)
local PLUGIN_DIR = vim.fn.fnamemodify(FILE_PATH, ':p:h:h:h')
NH.PLUGIN_DIR = PLUGIN_DIR -- Assign to global namespace

--- Load all Lua modules from a subdirectory inside the plugin's Lua folder
---@param subdir string
function M.load(subdir)
  local full_path = vim.fs.normalize(NH.PLUGIN_DIR .. '/lua/' .. subdir)

  -- Early exit if directory doesn't exist
  if vim.fn.isdirectory(full_path) == 0 then
    vim.notify('[NH] Missing directory: ' .. full_path, vim.log.levels.WARN)
    return
  end

  for name, type in vim.fs.dir(full_path) do
    if type == 'file' and name:sub(-4) == '.lua' then
      local module = subdir:gsub('/', '.') .. '.' .. name:match('(.+)%.lua$')
      local ok, err = pcall(require, module)
      if not ok then vim.notify('[NH] Error loading module: ' .. module .. '\n' .. err, vim.log.levels.ERROR) end
    end
  end
end

--- Entry point: load all plugin modules
function M.setup()
  vim.g.nvimhuda_is_loaded = vim.g.nvimhuda_is_loaded or false
  if not vim.g.nvimhuda_is_loaded then
    P(vim.g.nvimhuda_is_loaded)
    M.load('nvim-huda/config')
    M.load('nvim-huda/plugin')
    vim.g.nvimhuda_is_loaded = true
  end
end

return M
