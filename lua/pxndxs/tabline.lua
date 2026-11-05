-- Native tab line ('tabline'): tab pages only, shown from 2 tabs on ('showtabline' default); buffers live in the picker.
-- The current tab is a pill, like the statusline's; the others, the same pill in a faint tint of its color, like browser tabs.
-- Colors come from the colorscheme, so any theme works.
local M = {}

local theme = require("pxndxs.theme")
local nf = require("pxndxs.settings").nerd_font
local glyph = {
  left = nf and "\u{e0b6}" or " ",
  right = nf and "\u{e0b4}" or " ",
  changed = nf and "●" or "+",
}
local chrome = 5 -- cells around a label: pill edges, padding and the gap to the next one
local name_width = { min = 6, max = 24 }
local counter_width = 10 -- room for the "+N" of the tabs that do not fit, both sides

local color, mix = theme.color, theme.mix

local tint -- background of the pills that are not current
local icon_groups = {}

-- `c` moved toward `to` just enough for 3:1 on `on` (WCAG, symbols), keeping as much of its color as it can
local function stand_out(c, on, to)
  if not (c and on and to) then
    return c
  end
  for t = 0, 0.9, 0.1 do
    local mixed = mix(c, to, t)
    if theme.contrast(mixed, on) >= 3 then
      return mixed
    end
  end
  return c
end

local function set_highlights()
  local fg, bg = color("Normal", "fg"), theme.bg
  local accent = color("Function", "fg") or color("TabLineSel", "bg") or fg
  local changed = color("DiagnosticError", "fg")
  tint = accent and bg and mix(accent, bg, 0.75) or nil
  icon_groups = {}
  local function hl(name, spec)
    vim.api.nvim_set_hl(0, name, spec)
  end
  -- The gaps between pills; themes bring reverse or a mid gray here
  hl("TabLineFill", { bg = not theme.transparent and bg or nil })
  hl("PxTabCount", { fg = fg and bg and mix(fg, bg, 0.3) or color("Comment", "fg") })
  hl("PxTabEdge", { fg = accent })
  hl("PxTabCurrent", { fg = accent and (bg or 0), bg = accent, bold = true, reverse = not accent })
  hl("PxTabTintEdge", { fg = tint })
  hl("PxTabTint", { fg = fg, bg = tint })
  -- The theme's red, darker or lighter only as far as it needs to read on each pill
  hl("PxTabChangedCurrent", { fg = stand_out(changed, accent, bg), bg = accent, bold = true })
  hl("PxTabChanged", { fg = stand_out(changed, tint, fg), bg = tint })
end

-- An icon's color on the tint. Created on first use: mini.icons defines its groups after the first colorscheme
local function icon_group(name)
  local group = "PxTabIcon" .. name
  if not icon_groups[group] then
    vim.api.nvim_set_hl(0, group, { fg = color(name, "fg"), bg = tint })
    icon_groups[group] = true
  end
  return group
end

-- A float can have the focus (picker, command line): the tab is still about its regular window
local function main_win(tab)
  local current = vim.api.nvim_tabpage_get_win(tab)
  if vim.api.nvim_win_get_config(current).relative == "" then
    return current
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      return win
    end
  end
  return current
end

local function tab_info(tab)
  -- Regular windows only: the count should not jump while a picker or a hover is open
  local count, changed = 0, false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_config(win).relative == "" then
      count = count + 1
      changed = changed or vim.bo[vim.api.nvim_win_get_buf(win)].modified
    end
  end
  local buf = vim.api.nvim_win_get_buf(main_win(tab))
  if vim.bo[buf].buftype == "terminal" then
    return { path = "", name = "terminal", count = count, changed = changed }
  end
  local path = vim.api.nvim_buf_get_name(buf):gsub("/+$", "") -- directories end in /, oil's too
  local name = vim.fn.fnamemodify(path, ":t")
  return { path = path, name = name ~= "" and name or "new", count = count, changed = changed }
end

-- Keeps the end: the extension says more than the start
local function shorten(name, width)
  if vim.fn.strdisplaywidth(name) <= width then
    return name
  end
  return "…" .. vim.fn.strcharpart(name, vim.fn.strchars(name) - width + 1)
end

-- The cells of a label that do not depend on the name's width
local function measure(info)
  info.suffix = (info.count > 1 and " " .. info.count or "")
    .. (info.changed and " " .. glyph.changed or "")
  info.icon = ""
  if nf and info.path ~= "" and package.loaded["mini.icons"] then
    local icon, icon_hl = MiniIcons.get("file", info.path)
    info.icon, info.icon_hl = icon .. " ", icon_hl
  end
  info.fixed = chrome + vim.fn.strdisplaywidth(info.icon .. info.suffix)
  info.name_cells = vim.fn.strdisplaywidth(info.name)
end

local function label(info, n, is_current, width)
  local name = shorten(info.name, width)
  local edge, body, dot = "PxTabTintEdge", "PxTabTint", "PxTabChanged"
  if is_current then
    edge, body, dot = "PxTabEdge", "PxTabCurrent", "PxTabChangedCurrent"
  end
  local parts = { "%#", edge, "#", glyph.left, "%#", body, "# " }
  if info.icon_hl and not is_current then
    vim.list_extend(parts, { "%#", icon_group(info.icon_hl), "#", info.icon, "%#", body, "#" })
  else
    parts[#parts + 1] = info.icon
  end
  parts[#parts + 1] = name:gsub("%%", "%%%%") .. (info.count > 1 and " " .. info.count or "")
  if info.changed then
    vim.list_extend(parts, { " %#", dot, "#", glyph.changed, "%#", body, "#" })
  end
  vim.list_extend(parts, { " %#", edge, "#", glyph.right })
  return {
    text = ("%%%dT%s%%T%%#TabLineFill# "):format(n, table.concat(parts)),
    width = info.fixed + vim.fn.strdisplaywidth(name),
  }
end

function M.render()
  local tabs = vim.api.nvim_list_tabpages()
  local current = vim.api.nvim_tabpage_get_number(0)
  local columns = vim.o.columns

  local infos, names = {}, {}
  for i, tab in ipairs(tabs) do
    infos[i] = tab_info(tab)
    names[infos[i].name] = (names[infos[i].name] or 0) + 1
  end
  for _, info in ipairs(infos) do
    if names[info.name] > 1 and info.path ~= "" then
      info.name = vim.fn.fnamemodify(info.path, ":h:t") .. "/" .. info.name -- two tabs, same file name
    end
    measure(info)
  end

  -- Names shrink only as far as needed to fit, and the current one never
  local width = name_width.max
  while width > name_width.min do
    local needed = 0
    for i, info in ipairs(infos) do
      needed = needed
        + info.fixed
        + math.min(info.name_cells, i == current and name_width.max or width)
    end
    if needed <= columns then
      break
    end
    width = width - 1
  end

  local labels, total = {}, 0
  for i, info in ipairs(infos) do
    labels[i] = label(info, i, i == current, i == current and name_width.max or width)
    total = total + labels[i].width
  end

  -- The current tab always shows; the rest fill around it, and what does not fit is counted
  local first, last, used = current, current, labels[current].width
  local room = total > columns and columns - counter_width or columns
  local grew = true
  while grew do
    grew = false
    if last < #tabs and used + labels[last + 1].width <= room then
      last, used, grew = last + 1, used + labels[last + 1].width, true
    end
    if first > 1 and used + labels[first - 1].width <= room then
      first, used, grew = first - 1, used + labels[first - 1].width, true
    end
  end

  local out = {}
  if first > 1 then
    out[#out + 1] = ("%%%dT%%#PxTabCount# +%d %%T"):format(first - 1, first - 1)
  end
  for i = first, last do
    out[#out + 1] = labels[i].text
  end
  if last < #tabs then
    out[#out + 1] = ("%%%dT%%#PxTabCount# +%d %%T"):format(last + 1, #tabs - last)
  end
  return table.concat(out) .. "%#TabLineFill#"
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("pxndxs.tabline", {}),
  callback = set_highlights,
})
vim.o.tabline = "%!v:lua.require'pxndxs.tabline'.render()"

return M
