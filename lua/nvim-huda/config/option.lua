--------------------------------------------------------------------------------
-- Options
--------------------------------------------------------------------------------

-- UI
vim.o.number = true -- Show absolute line numbers
vim.o.relativenumber = true -- Show relative numbers
vim.o.signcolumn = 'yes' -- Always show sign column
vim.o.title = true -- Enable terminal title
vim.o.showmode = false -- Disable "-- INSERT --" mode since using statusline
vim.o.laststatus = 3 -- Global statusline (last window only)
vim.o.mouse = 'a' -- Enable mouse support
vim.o.termguicolors = true -- Enable 24-bit RGB colors (important for tmux)
vim.o.titlestring = [[%{&modified?'** ':''}%{empty(expand('%:F'))?'Nvim': 'Nvim: ' . expand('%:F')}]]
vim.o.list = true
vim.opt.listchars = { tab = '▏ ', trail = '·', extends = '»', precedes = '«' }

if vim.fn.has('nvim-0.12') == 1 then
  vim.o.pummaxwidth = 30 -- Limit maximum width of popup menu
  vim.o.completefuzzycollect = 'keyword,files,whole_line' -- Use fuzzy matching when collecting candidates

  require('vim._extui').enable({ enable = true })
end

-- Window & Split behavior
vim.o.wrap = false -- Disable line wrapping
vim.o.breakindent = true -- Preserve indent on wrapped lines
vim.o.splitbelow = true -- Horizontal split below
vim.o.splitright = true -- Vertical split right
vim.o.splitkeep = 'screen' -- Keep screen content stable during splits
vim.o.scrolloff = 10 -- Minimum lines above/below cursor when scrolling

-- Buffer & file behavior
vim.o.hidden = true -- Keep buffers loaded in background
vim.o.swapfile = false -- Don't create swap files
vim.o.writebackup = false -- Don't create backup before writing
vim.o.undofile = true -- Save undo history across sessions
vim.o.confirm = true -- Prompt to save unsaved changes

-- Search
vim.o.incsearch = true -- Show search results as you type
vim.o.hlsearch = false -- Don't highlight after search ends
vim.o.ignorecase = false -- Case-sensitive search
vim.o.smartcase = false -- Disable smart case

-- Tabs & Indentation
vim.o.tabstop = 2 -- Number of spaces per tab
vim.o.shiftwidth = 2 -- Indent width
vim.o.softtabstop = 2 -- Soft tab behavior
vim.o.expandtab = true -- Use spaces instead of tabs
vim.o.smartindent = true -- Auto-indent new lines

-- Performance
vim.o.synmaxcol = 1500 -- Don't syntax highlight long lines
vim.o.updatetime = 1000 -- Delay before triggering events (CursorHold)
vim.o.timeoutlen = 1000 -- Timeout for key sequence mappings
vim.o.switchbuf = 'useopen,uselast' -- jump to already open buffers on `:cn|:cp`

-- Folds
-- vim.o.foldmethod = 'indent' -- Set 'indent' folding method
-- vim.o.foldlevel = 1 -- Display all folds except top ones
-- vim.o.foldnestmax = 10 -- Create folds only for some number of nested levels
-- vim.g.markdown_folding = 1 -- Use folding by heading in markdown files

-- :find path search behavior
vim.cmd([[set path=.,,,$PWD/**]]) -- Recursive search in current dir

-- Disable providers we do not care a about
vim.g.loaded_python_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Disable some in built plugins completely
local disabled_built_ins = {
  "gzip",
  "zip",
  "zipPlugin",
  "tar",
  "tarPlugin",
  "getscript",
  "getscriptPlugin",
  "vimball",
  "vimballPlugin",
  "2html_plugin",
  "logipat",
  "rrhelper",
  "spellfile_plugin",
}
for _, plugin in pairs(disabled_built_ins) do
  vim.g["loaded_" .. plugin] = 1
end

--------------------------------------------------------------------------------
