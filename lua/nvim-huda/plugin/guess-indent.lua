--------------------------------------------------------------------------------
-- Guess Indent
--------------------------------------------------------------------------------
local function guess_indent(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= '' then return end

  -- skip if editorconfig sets indentation
  local ec = vim.b[bufnr].editorconfig
  if ec and (ec.indent_style or ec.indent_size or ec.tab_width) then return end

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, math.min(100, vim.api.nvim_buf_line_count(bufnr)), false)

  local space_indent = {}
  local tab_indent = 0

  for _, line in ipairs(lines) do
    if not line:match('^%s*$') then
      local indent = line:match('^%s+')
      if indent then
        if indent:find('^\t') then
          tab_indent = tab_indent + 1
        elseif indent:find('^ +') then
          local len = #indent
          space_indent[len] = (space_indent[len] or 0) + 1
        end
      end
    end
  end

  -- decide which style is dominant
  local most_common_space = 0
  local space_width = 0
  for len, count in pairs(space_indent) do
    if count > most_common_space then
      most_common_space = count
      space_width = len
    end
  end

  local ft = vim.bo[bufnr].filetype
  if ft == 'markdown' and space_width == 2 then return end

  local opts = { title = 'Guess Indent' }

  if tab_indent > most_common_space then
    if vim.bo[bufnr].expandtab then
      vim.bo[bufnr].expandtab = false
      vim.notify_once('Set indentation to tabs.', nil, opts)
    end
  elseif most_common_space > 0 then
    if not vim.bo[bufnr].expandtab or vim.bo[bufnr].shiftwidth ~= space_width then
      vim.bo[bufnr].expandtab = true
      vim.bo[bufnr].shiftwidth = space_width
      vim.bo[bufnr].softtabstop = space_width
      vim.notify_once(('Set indentation to %d spaces.'):format(space_width), nil, opts)
    end
  end
end

vim.api.nvim_create_autocmd('BufReadPost', {
  desc = 'Indent style',
  callback = function(ctx)
    vim.defer_fn(function() guess_indent(ctx.buf) end, 100)
  end,
})

--------------------------------------------------------------------------------
