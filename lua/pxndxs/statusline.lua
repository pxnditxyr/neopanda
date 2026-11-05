-- Native statusline (global, 'laststatus' 3): mode, git, file | busy, debug session, LSP progress, diagnostics, filetype,
-- position. Colors come from the colorscheme's own groups, so any theme works.
local M = {}

-- Nerd Font glyphs: rounded pill edges, git branch
local nf = require("pxndxs.settings").nerd_font
local glyph = {
  left = nf and "\u{e0b6}" or "",
  right = nf and "\u{e0b4}" or "",
  branch = nf and "\u{e0a0} " or "",
}

-- Name, color group, emoji (from neocats)
local modes = {
  n = { "NORMAL", "Function", "🐈" },
  no = { "O-PENDING", "Function", "🐾" },
  i = { "INSERT", "String", "🐼" },
  ic = { "INSERT", "String", "🐼" },
  ix = { "INSERT", "String", "🐼" },
  v = { "VISUAL", "Statement", "🐱" },
  V = { "V-LINE", "Statement", "🐯" },
  ["\22"] = { "V-BLOCK", "Statement", "🦢" },
  s = { "SELECT", "Statement", "🦋" },
  S = { "S-LINE", "Statement", "🦊" },
  ["\19"] = { "S-BLOCK", "Statement", "🐢" },
  R = { "REPLACE", "DiagnosticError", "🐳" },
  c = { "COMMAND", "Constant", "🦝" },
  t = { "TERMINAL", "DiagnosticOk", "🐚" },
  nt = { "N-TERM", "Function", "🐙" },
}

local color = require("pxndxs.theme").color

-- Mode pills: the accent of each mode as background
local function set_highlights()
  local theme_bg = require("pxndxs.theme").bg -- Normal's own can be empty (transparency)
  local bg = color("StatusLine", "bg") or theme_bg
  local dark = theme_bg or bg
  for _, group in ipairs({
    "Function",
    "String",
    "Statement",
    "DiagnosticError",
    "Constant",
    "DiagnosticOk",
  }) do
    local fg = color(group, "fg")
    vim.api.nvim_set_hl(0, "PxStlMode" .. group, { fg = dark, bg = fg, bold = true })
    vim.api.nvim_set_hl(0, "PxStlEdge" .. group, { fg = fg, bg = bg })
  end
  vim.api.nvim_set_hl(0, "PxStlDim", { fg = color("Comment", "fg"), bg = bg })
  vim.api.nvim_set_hl(0, "PxStlFile", { fg = color("Normal", "fg"), bg = bg, bold = true })
end

local function icon(buf)
  if not package.loaded["mini.icons"] then
    return ""
  end
  local icon_glyph, hl = MiniIcons.get("file", vim.api.nvim_buf_get_name(buf))
  return ("%%#%s#%s "):format(hl, icon_glyph)
end

local function file(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype == "terminal" then
    return "%#PxStlFile#terminal"
  elseif name == "" then
    return "%#PxStlDim#😶 [No Name]"
  end
  local path = vim.fn.fnamemodify(name, ":~:.")
  local dir, tail = vim.fn.fnamemodify(path, ":h"), vim.fn.fnamemodify(path, ":t")
  dir = dir == "." and "" or dir .. "/"
  local flags = (vim.bo[buf].modified and " 📝" or "")
    .. ((vim.bo[buf].readonly or not vim.bo[buf].modifiable) and " 🔒" or "")
    .. (vim.bo[buf].buftype == "" and not vim.uv.fs_stat(name) and " 🌚" or "") -- not on disk yet
  return icon(buf)
    .. "%#PxStlDim#"
    .. dir:gsub("%%", "%%%%")
    .. "%#PxStlFile#"
    .. tail:gsub("%%", "%%%%")
    .. flags
end

-- Filled by gitsigns when present
local function git(buf)
  local head = vim.b[buf].gitsigns_head
  if not head or head == "" then
    return ""
  end
  local status = vim.b[buf].gitsigns_status or ""
  return ("%%#PxStlDim#%s%s%s  "):format(glyph.branch, head, status ~= "" and " " .. status or "")
end

-- Debug session state ("Running", "Stopped at line 2"…), only while one is active (not "Closed session: N")
local function debug()
  local dap = package.loaded["dap"]
  local status = dap and dap.session() and dap.status() or ""
  return status ~= "" and "%#DiagnosticWarn#" .. status:gsub("%%", "%%%%") .. "  " or ""
end

function M.render()
  local buf = vim.api.nvim_get_current_buf()
  local mode = modes[vim.api.nvim_get_mode().mode]
    or modes[vim.api.nvim_get_mode().mode:sub(1, 1)]
    or modes.n
  local pill, edge = "%#PxStlMode" .. mode[2] .. "#", "%#PxStlEdge" .. mode[2] .. "#"
  local diagnostics = next(vim.diagnostic.count(buf)) and vim.diagnostic.status(buf) .. " " or ""
  local progress = vim.ui.progress_status and vim.ui.progress_status() or ""
  local ft = vim.bo[buf].filetype
  return table.concat({
    pill,
    " ",
    mode[3],
    " ",
    mode[1],
    " ",
    edge,
    glyph.right,
    " ",
    git(buf),
    "%<",
    file(buf),
    "%#PxStlDim#  🐼 pxndxs 😼",
    "%#StatusLine#%=",
    (vim.o.busy or 0) > 0 and "◐ " or "",
    debug(),
    progress ~= "" and "%#PxStlDim#" .. progress .. "  " or "",
    "%#StatusLine#",
    diagnostics,
    ft ~= "" and "%#PxStlDim#" .. ft .. "  " or "",
    edge,
    glyph.left,
    pill,
    " %l:%c  %P ",
  })
end

set_highlights()
local group = vim.api.nvim_create_augroup("pxndxs.statusline", {})
vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  callback = function()
    vim.cmd.redrawstatus()
  end,
})
vim.o.statusline = "%!v:lua.require'pxndxs.statusline'.render()"

return M
