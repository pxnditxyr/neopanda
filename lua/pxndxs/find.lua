-- 'findfunc' backed by fd (rg --files as fallback), fuzzy matched.
local M = {}

local cache

local function list_files()
  local cmd = vim.fn.executable("fd") == 1
      and { "fd", "--type", "f", "--hidden", "--exclude", ".git" }
    or { "rg", "--files", "--hidden", "--glob", "!.git" }
  local out = vim.system(cmd, { text = true }):wait().stdout or ""
  return vim.split(out, "\n", { trimempty = true })
end

function M.find(arg, _)
  cache = cache or list_files()
  return arg == "" and cache or vim.fn.matchfuzzy(cache, arg)
end

-- Refresh the file list on every new command line.
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = vim.api.nvim_create_augroup("pxndxs.find", {}),
  pattern = ":",
  callback = function()
    cache = nil
  end,
})

return M
