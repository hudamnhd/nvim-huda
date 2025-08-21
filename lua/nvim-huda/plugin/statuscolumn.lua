--------------------------------------------------------------------------------
-- Status column
--------------------------------------------------------------------------------
local sc = {}

sc.border = function() return '│' end
sc.signs = function() return vim.o.signcolumn and '%s' or ' ' end
sc.number = function()
  local number_len = math.max(string.len(vim.fn.line('.')), 3)
  local number = vim.o.relativenumber and vim.v.relnum or vim.v.lnum

  if number == 0 then number = vim.v.lnum end

  return string.format('%' .. number_len .. 's ', number)
end

sc.statuscolumn = function()
  return table.concat({
    sc.signs(),
    sc.number(),
    sc.border(),
  })
end

-- _G._my.statuscolumn = sc.statuscolumn
-- vim.o.statuscolumn = '%!v:lua._my.statuscolumn()'
--------------------------------------------------------------------------------
