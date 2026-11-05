-- Colorscheme, transparency and glass, remembered in stdpath("state")/theme.json. Both are applied here and not by each
-- theme, so they look the same in all of them. Transparency removes the editor's background; glass, the floats'.
-- Selection and diffs stay solid.
local M = {}

local path = vim.fn.stdpath("state") .. "/theme.json"

local ok, state = pcall(function()
  return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
end)
state = ok and type(state) == "table" and state or {}

local default_transparent = require("pxndxs.settings").transparent
M.transparent = state.transparent
if type(M.transparent) ~= "boolean" then
  M.transparent = default_transparent
end
M.glass = state.glass == true

local function normal_bg()
  return vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
end

-- Normal's background as the theme defines it, empty under transparency in the group itself.
-- For code that derives colors from it (statusline pills, AI ghost text).
M.bg = normal_bg()

function M.color(name, attr)
  return vim.api.nvim_get_hl(0, { name = name, link = false })[attr]
end

local function linear_rgb(c)
  local function lin(x)
    x = x / 255
    return x <= 0.04045 and x / 12.92 or ((x + 0.055) / 1.055) ^ 2.4
  end
  return lin(bit.rshift(c, 16)), lin(bit.band(bit.rshift(c, 8), 255)), lin(bit.band(c, 255))
end

-- WCAG contrast ratio of two colors
function M.contrast(a, b)
  local function luminance(c)
    local r, g, bl = linear_rgb(c)
    return 0.2126 * r + 0.7152 * g + 0.0722 * bl
  end
  local x, y = luminance(a), luminance(b)
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05)
end

-- OKLab: perceptual, no muddy mid-tones
local function oklab(c)
  local r, g, b = linear_rgb(c)
  local l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ^ (1 / 3)
  local m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ^ (1 / 3)
  local s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ^ (1 / 3)
  return {
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  }
end

-- `a` moved toward `b` by `t` (0..1)
function M.mix(a, b, t)
  local x, y = oklab(a), oklab(b)
  local L, A, B = x[1] + (y[1] - x[1]) * t, x[2] + (y[2] - x[2]) * t, x[3] + (y[3] - x[3]) * t
  local l = (L + 0.3963377774 * A + 0.2158037573 * B) ^ 3
  local m = (L - 0.1055613458 * A - 0.0638541728 * B) ^ 3
  local s = (L - 0.0894841775 * A - 1.2914855480 * B) ^ 3
  local function srgb(v)
    v = math.min(math.max(v, 0), 1)
    return math.floor(255 * (v <= 0.0031308 and 12.92 * v or 1.055 * v ^ (1 / 2.4) - 0.055) + 0.5)
  end
  return srgb(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s) * 0x10000
    + srgb(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s) * 0x100
    + srgb(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s)
end

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
}

-- Glass: floats without a background, so the terminal shows through. Selection groups stay solid.
-- Parents first: groups linked to them resolve to no background and are left linked.
local glass = {
  "NormalFloat",
  "FloatBorder",
  "FloatTitle",
  "FloatFooter",
  "Pmenu",
  "PmenuMatch",
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

local function drop_bg(name, hl)
  hl.bg, hl.ctermbg = nil, nil
  ---@diagnostic disable-next-line: param-type-mismatch (what get_hl returns, set_hl takes)
  vim.api.nvim_set_hl(0, name, hl)
end

local function clear_bg(names)
  for _, name in ipairs(names) do
    local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
    if hl.bg then
      drop_bg(name, hl)
    end
  end
end

-- Whatever paints the theme's own background (start screen items, help headings) would stay as a solid patch.
-- Only for transparency: floats share their background with the statusline and code blocks, hence glass's list.
local function clear_editor_bg()
  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if M.bg and hl.bg == M.bg then
      drop_bg(name, hl)
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
      clear_editor_bg()
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
    -- Only a real toggle is remembered: the default in settings.lua keeps working otherwise
    local transparent = nil
    if M.transparent ~= default_transparent then
      transparent = M.transparent
    end
    vim.fn.writefile({
      vim.json.encode({
        colorscheme = vim.g.colors_name,
        background = vim.o.background, -- some themes have both variants (retrobox)
        transparent = transparent,
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
