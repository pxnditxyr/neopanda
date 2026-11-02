-- Native git helpers: lazygit in a floating terminal, open in the browser.
-- gitsigns lives in plugins/git.lua, the git pickers in plugins/ui.lua.
local M = {}

---@return string? output trimmed, nil on failure
local function git(dir, ...)
  local res = vim.system({ "git", "-C", dir, ... }, { text = true }):wait()
  return res.code == 0 and vim.trim(res.stdout) or nil
end

local function dir()
  local name = vim.api.nvim_buf_get_name(0)
  return name ~= "" and vim.bo.buftype == "" and vim.fs.dirname(name) or vim.fn.getcwd()
end

-- Color of a highlight group as a lazygit color, or the terminal default
local function color(group, attr)
  local c = vim.api.nvim_get_hl(0, { name = group, link = false })[attr]
  return c and ("'#%06x'"):format(c) or "default"
end

-- lazygit config: the user's own file plus ours, rewritten on each open so the theme follows the
-- colorscheme (edits open in this nvim through $NVIM)
local base
local function lazygit_config()
  if base == nil then
    base = vim.env.LG_CONFIG_FILE
    if not base then
      local cfg_dir = vim.fn.system({ "lazygit", "--print-config-dir" }):gsub("%s+$", "")
      base = vim.fs.joinpath(cfg_dir, "config.yml")
      base = vim.uv.fs_stat(base) and base or false
    end
  end
  local own = vim.fs.joinpath(vim.fn.stdpath("state"), "lazygit.yml")
  vim.fn.writefile({
    "os:",
    "  editPreset: nvim-remote",
    "gui:",
    "  theme:",
    "    activeBorderColor: [" .. color("Function", "fg") .. ", bold]",
    "    inactiveBorderColor: [" .. color("Comment", "fg") .. "]",
    "    searchingActiveBorderColor: [" .. color("Constant", "fg") .. ", bold]",
    "    optionsTextColor: [" .. color("Function", "fg") .. "]",
    "    selectedLineBgColor: [" .. color("Visual", "bg") .. "]",
    "    inactiveViewSelectedLineBgColor: [" .. color("CursorLine", "bg") .. "]",
    "    cherryPickedCommitFgColor: [" .. color("Function", "fg") .. "]",
    "    cherryPickedCommitBgColor: [" .. color("Visual", "bg") .. "]",
    "    unstagedChangesColor: [" .. color("DiagnosticError", "fg") .. "]",
    "    defaultFgColor: [" .. color("Normal", "fg") .. "]",
  }, own)
  return base and base .. "," .. own or own
end

function M.lazygit()
  if vim.fn.executable("lazygit") == 0 then
    return vim.notify("lazygit not found", vim.log.levels.WARN)
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local width, height = math.floor(vim.o.columns * 0.9), math.floor(vim.o.lines * 0.9)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
  })
  vim.fn.jobstart({ "lazygit" }, {
    term = true,
    cwd = dir(),
    env = {
      LG_CONFIG_FILE = lazygit_config(),
      -- The nvim-remote preset calls `nvim`: make it this binary
      PATH = vim.fs.dirname(vim.v.progpath) .. ":" .. vim.env.PATH,
    },
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      vim.cmd.checktime()
    end,
  })
  vim.cmd.startinsert()
end

-- File (and line range) on the origin remote: GitHub style, GitLab style for gitlab hosts
function M.browse()
  local file = vim.api.nvim_buf_get_name(0)
  local cwd = vim.fs.dirname(file)
  local remote = file ~= "" and git(cwd, "remote", "get-url", "origin")
  local path = remote and git(cwd, "ls-files", "--full-name", "--", file)
  if not path or path == "" then
    return vim.notify("Not a tracked file with an origin remote", vim.log.levels.WARN)
  end
  local url = remote
    :gsub("%.git$", "")
    :gsub("^git@([^:]+):", "https://%1/")
    :gsub("^ssh://[^@]+@([^/:]+)[:%d]*/", "https://%1/")
    :gsub("^https://[^@/]+@", "https://")
  local ref = git(cwd, "rev-parse", "--abbrev-ref", "HEAD")
  if ref == "HEAD" then
    ref = git(cwd, "rev-parse", "HEAD") -- detached
  end
  local first, last = vim.fn.line("v"), vim.fn.line(".")
  first, last = math.min(first, last), math.max(first, last)
  local gitlab = url:find("gitlab") ~= nil
  local lines = first == last and ("#L%d"):format(first)
    or (gitlab and "#L%d-%d" or "#L%d-L%d"):format(first, last)
  vim.ui.open(("%s/%sblob/%s/%s%s"):format(url, gitlab and "-/" or "", ref, path, lines))
end

vim.keymap.set("n", "<leader>gg", M.lazygit, { desc = "Lazygit" })
vim.keymap.set({ "n", "x" }, "<leader>go", M.browse, { desc = "Open in browser" })

return M
