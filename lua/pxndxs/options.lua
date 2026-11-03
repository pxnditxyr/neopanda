vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- UI
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = "no" -- signs are drawn by the statuscolumn (statuscolumn.lua)
vim.o.cursorline = true
vim.o.cursorlineopt = "number"
vim.o.laststatus = 3
vim.o.showmode = false
vim.o.guicursor = ""
vim.o.mouse = ""
vim.o.winborder = "rounded"
vim.o.list = true
vim.o.listchars = "tab:» ,trail:·,nbsp:␣"
vim.o.fillchars = "eob: "

-- Editing / indent
vim.o.expandtab = true
vim.o.tabstop = 2
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.wrap = false
vim.o.breakindent = true
vim.o.linebreak = true
vim.o.virtualedit = "block"
vim.o.spelllang = "en_us"
vim.o.confirm = true

-- Search
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.inccommand = "split"
vim.o.grepprg = "rg --vimgrep --smart-case"
vim.o.findfunc = "v:lua.require'pxndxs.find'.find"

-- Files / undo / session
vim.o.undofile = true
vim.o.undolevels = 10000
vim.o.sessionoptions = "buffers,curdir,tabpages,winsize" -- no help/terminal: they restore empty

-- Folds (foldmethod/foldexpr are set per filetype with treesitter)
vim.o.foldlevelstart = 99
vim.o.foldtext = ""

-- Windows / splits / scroll
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.splitkeep = "screen"
vim.o.smoothscroll = true
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8
vim.o.tabclose = "uselast"
vim.o.jumpoptions = "stack,view"
vim.opt.diffopt:append("algorithm:histogram")

-- Completion / popup / cmdline
vim.o.pumheight = 10
vim.o.pummaxwidth = 50
vim.o.pumborder = "rounded"
vim.o.completeopt = "menuone,noselect,popup,fuzzy,nearest"
vim.o.autocomplete = true
vim.o.complete = ".,w,b,u,t,o"
vim.opt.shortmess:append("c")
vim.o.wildmode = "noselect:lastused,full"
vim.opt.wildoptions:append("fuzzy")

-- Timing
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Over SSH, copy with OSC 52: setting 'clipboard' turns off its auto-detection, and on a remote
-- mac pbcopy would copy there. Terminals often block OSC 52 reads, so paste uses the unnamed register.
if require("pxndxs.env").is_ssh then
  local osc52 = require("vim.ui.clipboard.osc52")
  local function paste()
    return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
    paste = { ["+"] = paste, ["*"] = paste },
  }
end

-- Deferred: loading the clipboard provider costs startup time.
vim.schedule(function()
  vim.o.clipboard = "unnamedplus"
end)

-- 0.13-dev only
pcall(function()
  vim.opt.shortmess:append("u")
end)
pcall(function()
  vim.o.scrolloffpad = 1
end)

-- Providers (no remote plugins)
vim.g.loaded_python3_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_remote_plugins = 1
