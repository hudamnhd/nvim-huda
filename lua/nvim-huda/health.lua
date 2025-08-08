local M = {}

local uv = vim.uv or vim.loop

local function check_version()
  local v = vim.version()

  -- Construct version string
  local verstr = string.format("%d.%d.%d", v.major, v.minor, v.patch)

  if v.major > 0 or (v.minor >= 10) then
    vim.health.ok("Neovim version is: " .. verstr)
  else
    vim.health.error("Neovim out of date: " .. verstr .. ". Upgrade to 0.10+ (stable or nightly)")
  end
end

local function check_external_reqs()
  local required = { 'git', 'fzf', 'nnn', 'rg', 'gitui' }

  for _, exe in ipairs(required) do
    if vim.fn.executable(exe) == 1 then
      vim.health.ok("Found executable: " .. exe)
    else
      vim.health.report_warn("Missing executable: " .. exe)
    end
  end
end

function M.check()
  vim.health.start('nvim-huda')

  -- Show system info
  vim.health.info("System Information: " .. vim.inspect(uv.os_uname()))

  check_version()
  check_external_reqs()
end

return M
