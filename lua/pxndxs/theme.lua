-- Colorscheme, transparency and glass, remembered in stdpath("state")/theme.json. Both are applied here and not by each
-- theme, so they look the same in all of them. Transparency removes the editor's background; glass, the floats'.
-- Selection and diffs stay solid.
local M = {}

local path = vim.fn.stdpath("state") .. "/theme.json"

local ok, state = pcall(function()
  return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
end)
state = ok and type(state) == "table" and state or {}

M.transparent = state.transparent
if type(M.transparent) ~= "boolean" then
  M.transparent = require("pxndxs.settings").transparent
end
M.glass = state.glass == true

local function normal_bg()
  return vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
end

-- Normal's background as the theme defines it, empty under transparency in the group itself.
-- For code that derives colors from it (statusline pills, AI ghost text).
M.bg = normal_bg()

local clear = {
  "Normal",
  "NormalNC",
  "EndOfBuffer",
  "MsgArea",
  "MsgSeparator",
  "VertSplit",
  "WinSeparator",
  "ModeMsg",
  "MoreMsg",
  "ErrorMsg",
  "WarningMsg",
  "SignColumn",
  "FoldColumn",
  "LineNr",
  "TabLineFill",
}

-- Glass: floats without a background, so the terminal shows through. Selection groups stay solid.
-- Parents first: groups linked to them resolve to no background and are left linked.
local glass = {
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "FloatFooter",
  "Pmenu",
  "PmenuBorder",
  "PmenuKind",
  "PmenuExtra",
  "MiniPickNormal",
  "MiniPickBorder",
  "MiniPickBorderBusy",
  "MiniPickBorderText",
  "MiniPickPrompt",
  "MiniPickPromptCaret",
  "MiniPickPromptPrefix",
  "MiniPickHeader",
  "MiniPickIconFile",
  "MiniPickIconDirectory",
  "MiniPickMatchRanges",
}

local function clear_bg(names)
  for _, name in ipairs(names) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.bg then
      hl.bg, hl.ctermbg = nil, nil
      ---@diagnostic disable-next-line: param-type-mismatch (what get_hl returns, set_hl takes)
      vim.api.nvim_set_hl(0, name, hl)
    end
  end
end

local group = vim.api.nvim_create_augroup("pxndxs.theme", {})
-- This module loads before the ones that read M.bg, so this autocmd runs before theirs
vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = function()
    M.bg = normal_bg()
    if M.transparent then
      clear_bg(clear)
    end
    if M.glass then
      clear_bg(glass)
    end
  end,
})

-- On exit and not on ColorScheme: the picker's previews also fire it
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile({
      vim.json.encode({
        colorscheme = vim.g.colors_name,
        background = vim.o.background, -- some themes have both variants (retrobox)
        transparent = M.transparent,
        glass = M.glass,
      }),
    }, path)
  end,
})

-- Saved theme, or the default if it is gone
function M.apply()
  if state.background == "light" or state.background == "dark" then
    vim.o.background = state.background
  end
  if not (state.colorscheme and pcall(vim.cmd.colorscheme, state.colorscheme)) then
    vim.cmd.colorscheme("michipanda")
  end
end

-- Like VS Code: moving applies the theme under the cursor, canceling restores the previous one.
-- The current theme goes first, so opening the picker changes nothing. Needs mini.pick and mini.extra loaded.
function M.pick()
  local name, background = vim.g.colors_name or "default", vim.o.background
  local shown = name
  local names = vim.tbl_filter(function(n)
    return n ~= name
  end, vim.fn.getcompletion("", "color"))
  table.insert(names, 1, name)

  local function show(buf, items, query)
    MiniPick.default_show(buf, items, query)
    local current = (MiniPick.get_picker_matches() or {}).current
    if current and current ~= shown then
      shown = current
      vim.o.background = background -- a previous preview may have changed it
      pcall(vim.cmd.colorscheme, current)
    end
  end

  local picked = MiniExtra.pickers.colorschemes({ names = names }, { source = { show = show } })
  if picked == nil and shown ~= name then
    vim.o.background = background
    vim.cmd.colorscheme(name)
  end
end

local function toggle(lhs, key, label)
  vim.keymap.set("n", lhs, function()
    M[key] = not M[key]
    vim.cmd.colorscheme(vim.g.colors_name or "default") -- reloading restores what the theme defines
    vim.notify(label .. ": " .. (M[key] and "on" or "off"))
  end, { desc = "Toggle " .. label:lower() })
end
toggle("<leader>uT", "transparent", "Transparency")
toggle("<leader>ug", "glass", "Glass")

return M
