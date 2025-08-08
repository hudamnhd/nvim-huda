local M = {}
local cache_file = vim.fn.stdpath('cache') .. '/mru'
local max_entries = 100

local mru_list = {}
local mru_set = {}

local function load_from_file()
  local f = io.open(cache_file, 'r')
  if not f then return end

  for line in f:lines() do
    if not mru_set[line] then
      table.insert(mru_list, line)
      mru_set[line] = true
    end
  end
  f:close()
end

function M.add(file_path)
  if mru_set[file_path] then return end

  table.insert(mru_list, 1, file_path)
  mru_set[file_path] = true

  -- Potong kalau terlalu banyak
  if #mru_list > max_entries then
    for i = max_entries + 1, #mru_list do
      mru_set[mru_list[i]] = nil
    end
    mru_list = { unpack(mru_list, 1, max_entries) }
  end
end

function M.list() return mru_list end

function M.write_to_file()
  vim.fn.mkdir(vim.fn.fnamemodify(cache_file, ':h'), 'p')
  local f = io.open(cache_file, 'w')
  if not f then return end

  for _, path in ipairs(mru_list) do
    f:write(path .. '\n')
  end
  f:close()
end

vim.api.nvim_create_autocmd('UIEnter', {
  once = true,
  callback = vim.schedule_wrap(function() load_from_file() end),
})

vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function(ctx)
    local bufnr = ctx.buf
    if vim.bo[bufnr].buftype ~= '' then return end

    local file = vim.uv.fs_realpath(ctx.file or '')
    if not file or vim.fn.isdirectory(file) == 1 then return end
    M.add(file)
  end,
})

vim.api.nvim_create_autocmd({ 'VimLeavePre', 'FocusLost', 'VimSuspend' }, {
  callback = function() M.write_to_file() end,
})

_G.NH.mru = M.list

return M
