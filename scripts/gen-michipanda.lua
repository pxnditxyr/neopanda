-- Generates colors/michipanda.lua: tokyonight storm with our palette, frozen by mini.colors. Run it after changing the
-- palette, from anywhere: nvim --clean -l scripts/gen-michipanda.lua
-- The result needs no plugin. Plugin groups come from tokyonight's list, so a plugin it does not know keeps its defaults.
local repo = vim.fs.dirname(vim.fs.dirname(vim.fs.abspath(arg[0])))
local tmp = vim.fn.tempname()

local function clone(url, rev)
  local dir = tmp .. "/" .. vim.fs.basename(url)
  for _, cmd in ipairs({
    { "git", "clone", "--quiet", "--filter=blob:none", url, dir },
    { "git", "-C", dir, "checkout", "--quiet", rev },
  }) do
    local res = vim.system(cmd):wait()
    assert(res.code == 0, res.stderr)
  end
  vim.opt.runtimepath:prepend(dir)
end
clone("https://github.com/folke/tokyonight.nvim", "cdc07ac78467a233fd62c493de29a17e0cf2b2b6")
clone("https://github.com/nvim-mini/mini.colors", "ace7e16d42ac27d08d5fd5e16f1ee29ed80e42b3")

-- Transparency is not part of the theme: lua/pxndxs/theme.lua applies it to any theme
require("tokyonight").load({
  style = "storm",
  on_colors = function(c)
    c.bg_dark = "#1f2335"
    c.bg = "#24283b"
    c.bg_highlight = "#0f172a" -- current line
    c.terminal_black = "#414868"
    c.fg = "#fde68a" -- text
    c.fg_dark = "#a9b1d6"
    c.fg_gutter = "#3b4261"
    c.dark3 = "#545c7e"
    c.comment = "#895f89"
    c.dark5 = "#737aa2" -- current line number
    c.blue0 = "#3d59a1"
    c.blue = "#0CECDD" -- function calls, methods
    c.cyan = "#0bf947"
    c.blue1 = "#2ac3de"
    c.blue2 = "#0db9d7"
    c.blue5 = "#89ddff"
    c.blue6 = "#B4F9F8"
    c.blue7 = "#394b70"
    c.magenta = "#f43f5e" -- keywords: if, for, while
    c.magenta2 = "#d946ef"
    c.purple = "#FF33BB" -- return, local
    c.orange = "#ff9e64"
    c.yellow = "#fde047"
    c.green = "#a3e635"
    c.green1 = "#34d399"
    c.green2 = "#4ade80"
    c.teal = "#0d9488"
    c.red = "#ef4444"
    c.red1 = "#dc2626"
    c.git = { change = "#FDFD44", add = "#9CFF2E", delete = "#ef4444", conflict = "#bb7a61" }
    c.gitSigns = { add = "#9CFF2E", change = "#FDFD44", delete = "#ef4444" }
  end,
  on_highlights = function(hl, c)
    hl.FloatBorder = { fg = c.blue }
    hl.NormalFloat = { bg = c.bg_dark }
    hl.DiagnosticFloatingError = { fg = c.red }
    hl.DiagnosticFloatingWarn = { fg = c.yellow }
    hl.DiagnosticFloatingInfo = { fg = c.blue }
    hl.DiagnosticFloatingHint = { fg = c.cyan }
  end,
})

local colors = require("mini.colors").get_colorscheme(nil, { new_name = "michipanda" })
colors:write({ directory = repo .. "/colors" })

-- mini.colors does not write 'background'
local path = repo .. "/colors/michipanda.lua"
local lines = vim.fn.readfile(path)
table.insert(lines, 1, 'vim.o.background = "dark"')
vim.fn.writefile(lines, path)

vim.fn.delete(tmp, "rf")
print(path)
