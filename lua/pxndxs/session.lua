-- Sessions, native (:mksession): one per cwd, plus the git branch when it is not main/master, kept in
-- stdpath("state")/sessions/. Saved on exit and restored when nvim starts with no file and no stdin.
-- Same naming as folke/persistence.nvim.
local M = {}

local dir = vim.fn.stdpath("state") .. "/sessions/"
local save_on_exit = true
local from_stdin = false

local function escape(s)
  return (s:gsub("[\\/:]+", "%%"))
end

local function branch()
  if not vim.uv.fs_stat(".git") then
    return nil
  end
  local out = vim.system({ "git", "branch", "--show-current" }, { text = true }):wait()
  local name = vim.trim(out.stdout or "")
  if out.code ~= 0 or name == "" or name == "main" or name == "master" then
    return nil
  end
  return name
end

---@param with_branch? boolean false: the plain cwd session
local function file(with_branch)
  local name = escape(vim.fn.getcwd())
  local b = with_branch ~= false and branch()
  if b then
    name = name .. "%%" .. escape(b)
  end
  return dir .. name .. ".vim"
end

local function shows_nothing()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local bo = vim.bo[buf]
    if
      vim.api.nvim_win_get_config(win).relative == ""
      and (vim.api.nvim_buf_get_name(buf) ~= "" or bo.buftype ~= "" or bo.modified)
    then
      return false
    end
  end
  return true
end

local function source(path)
  vim.cmd("silent! source " .. vim.fn.fnameescape(path))
  -- Saved from an empty window: files only in the buffer list. mini.starter skips listed buffers, so nothing would draw
  if shows_nothing() and _G.MiniStarter then
    vim.cmd("silent! tabonly | silent! only")
    MiniStarter.open()
  end
end

local function sessions()
  local list = vim.fn.glob(dir .. "*.vim", true, true)
  table.sort(list, function(a, b)
    return vim.fn.getftime(a) > vim.fn.getftime(b)
  end)
  return list
end

function M.save()
  local files = 0
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local bo = vim.bo[buf]
    if bo.buftype ~= "" then
      -- oil, grug-far, directory, help, terminal, quickfix… would come back broken
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    elseif
      vim.api.nvim_buf_get_name(buf) ~= ""
      and not vim.list_contains({ "gitcommit", "gitrebase", "jj" }, bo.filetype)
    then
      files = files + 1
    end
  end
  if files == 0 then
    return -- keep the previous session
  end
  vim.fn.mkdir(dir, "p")
  vim.cmd("mksession! " .. vim.fn.fnameescape(file()))
end

function M.load()
  local path = file()
  if vim.fn.filereadable(path) == 0 then
    path = file(false) -- branch without a session yet
  end
  if vim.fn.filereadable(path) == 1 then
    source(path)
  end
end

local group = vim.api.nvim_create_augroup("pxndxs.session", {})
vim.api.nvim_create_autocmd("StdinReadPre", {
  group = group,
  callback = function()
    from_stdin = true
  end,
})
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  nested = true, -- buffers fire BufRead/FileType: highlight, LSP
  desc = "Restore the session of the cwd",
  callback = function()
    -- Opened with files or stdin: not a project session, neither restored nor saved
    if vim.fn.argc(-1) > 0 or from_stdin then
      save_on_exit = false
    elseif (vim.v.startreason or "normal") == "normal" then -- :restart restores its own session (0.13+)
      M.load()
    end
  end,
})
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  desc = "Save the session of the cwd",
  callback = function()
    if save_on_exit then
      M.save()
    end
  end,
})

local map = vim.keymap.set
map("n", "<leader>qs", M.load, { desc = "Restore session (cwd)" })
map("n", "<leader>ql", function()
  local last = sessions()[1]
  if last then
    source(last)
  end
end, { desc = "Restore last session" })
map("n", "<leader>qS", function()
  vim.ui.select(sessions(), {
    prompt = "Session",
    format_item = function(path)
      return (vim.fn.fnamemodify(path, ":t:r"):gsub("%%", "/"))
    end,
  }, function(path)
    if path then
      source(path)
    end
  end)
end, { desc = "Pick session" })
map("n", "<leader>qd", function()
  save_on_exit = false
  vim.notify("Session: not saved on exit")
end, { desc = "Don't save session on exit" })
map("n", "<leader>qq", "<Cmd>qa<CR>", { desc = "Quit all" })

return M
