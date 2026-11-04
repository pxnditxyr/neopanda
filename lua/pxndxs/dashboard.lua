-- Header for the start screen (mini.starter, plugins/ui.lua): the panda art, shrunk to fit the window.
local text = [[
   _ (`-. ) (`-.          .-') _  _ .-') _ ) (`-.       .-')
  ( (OO  ) ( OO ).       ( OO ) )( (  OO) ) ( OO ).    ( OO ).
 _.`     \(_/.  \_)-.,--./ ,--,'  \     .'_(_/.  \_)-.(_)---\_)
(__...--'' \  `.'  / |   \ |  |\  ,`'--..._)\  `.'  / /    _ |
 |  /  | |  \     /\ |    \|  | ) |  |  \  ' \     /\ \  :` `.
 |  |_.' |   \   \ | |  .     |/  |  |   ' |  \   \ |  '..`''.)
 |  .___.'  .'    \_)|  |\    |   |  |   / : .'    \_).-._)   \
 |  |      /  .'.  \ |  | \   |   |  '--'  //  .'.  \ \       /
 `--'     '--'   '--'`--'  `--'   `-------''--'   '--' `-----']]
local panda = [[
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣄⡀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⡀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣟⠻⣿⡽⣹⣷⠆⣸⣿⣿⣿⣿
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⠟⠙⣿⡏⠀⠈⣿⡋⢾⣏⠰⢻⡃⠸⢻⣿⣿⣿⡟
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠻⢿⣿⣷⣶⣿⣷⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠟⠛⠋⠉⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⠀⠀⠀⠀⢀⣀⣠⣶⣿⠷⣶⣤⣄⣀⣤⣶⣶⣦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣷⡶⠚⠋⠉⠉⠁⠀⠀⠀⠀⠈⠉⠛⢿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣾⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣿⣿⠇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣧⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡇⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢀⣴⣶⣿⣷⣦⡀⢀⣀⣾⠃⠀⠀⠀⠀⠀⣀⣠⣤⣤⣄⣀⠀⠀⠀⠀⠀⠀⠀⢠⣶⣾⣿⣾⣿⡀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⢸⣿⣿⣿⣿⠿⠛⠋⢹⡏⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠘⢿⣿⠟⠁⠀⠀⠀⣼⡇⠀⠀⠀⠀⣿⣿⣿⣿⣿⣛⣿⣿⣿⡇⠀⠀⠀⠀⠀⢹⣿⣿⣭⣽⣿⣿⣷⡄⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣼⠃⠀⠀⠀⠀⠀⢻⡇⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀⠀⣠⣤⣤⡄⠉⠻⠿⠿⠿⠛⠘⣷⠀⠀⠀⠀
⠀⠀⠀⠀⢰⡏⠀⠀⠀⠀⠀⠀⠸⣧⠀⠀⠀⠀⠀⠙⠻⠿⠿⠟⠛⠁⠀⠀⠀⠀⠈⠙⠋⠀⠀⠀⠀⠀⠀⠀⢠⡟⠀⠀⠀⠀
⠀⣠⣤⣤⣸⡇⠀⠀⠀⠀⠀⠀⢠⣿⣿⣿⣶⣦⣄⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣿⡁⠀⠀⠀⠀
⢸⣿⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣾⣿⣿⣿⡆⠀⠀⠀
⠘⢿⣿⣿⣿⣿⣷⣤⣤⣤⣤⣤⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣁⣀⣀⣤⣤⣤⣶⣾⣿⣿⣿⣿⣿⣿⣿⠿⠁⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀]]

local M = {}

-- Spaces that center `str` under the art (the art sets the width of the whole block)
function M.pad(str)
  local width = 0
  for _, l in ipairs(vim.split(text, "\n")) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
  end
  return string.rep(" ", math.max(0, math.floor((width - vim.fn.strdisplaywidth(str)) / 2)))
end

-- Full art (text + panda) when it fits with the menu, else only the text, else nothing
function M.header()
  local menu = 15 -- items, footer, blank lines, statusline and command line
  local text_h, panda_h = #vim.split(text, "\n"), #vim.split(panda, "\n")
  if vim.o.lines >= text_h + panda_h + menu then
    local centered = vim.tbl_map(function(l)
      return M.pad(l) .. l
    end, vim.split(panda, "\n"))
    return text .. "\n" .. table.concat(centered, "\n")
  elseif vim.o.lines >= text_h + menu then
    return text
  end
  return ""
end

-- Header colors from the colorscheme's own groups (any theme works), blended line by line
local stops = { "Keyword", "Function", "Character" }

local function rgb(group)
  local c = vim.api.nvim_get_hl(0, { name = group, link = false }).fg or 0xffffff
  return { math.floor(c / 0x10000), math.floor(c / 0x100) % 0x100, c % 0x100 }
end

-- Content hook: each header line gets its own highlight group along the gradient
function M.gradient(content)
  local header = {}
  for _, line in ipairs(content) do
    for _, unit in ipairs(line) do
      if unit.type == "header" then
        header[#header + 1] = unit
      end
    end
  end
  local colors = vim.tbl_map(rgb, stops)
  for i, unit in ipairs(header) do
    local t = (#header > 1 and (i - 1) / (#header - 1) or 0) * (#colors - 1)
    local k = math.min(math.floor(t), #colors - 2)
    local a, b, f = colors[k + 1], colors[k + 2], t - k
    local c = {}
    for j = 1, 3 do
      c[j] = math.floor(a[j] + (b[j] - a[j]) * f + 0.5)
    end
    unit.hl = "PxStarterHeader" .. i
    vim.api.nvim_set_hl(0, unit.hl, { fg = c[1] * 0x10000 + c[2] * 0x100 + c[3] })
  end
  return content
end

-- Branch of the cwd's repo, read from .git/HEAD (no git process at startup); nil outside a repo or in a worktree
function M.branch()
  local root = vim.fs.root(vim.fn.getcwd(), ".git")
  local f = root and io.open(root .. "/.git/HEAD")
  if not f then
    return nil
  end
  local head = f:read("l")
  f:close()
  return head and (head:match("^ref: refs/heads/(.+)$") or head:sub(1, 7))
end

return M
