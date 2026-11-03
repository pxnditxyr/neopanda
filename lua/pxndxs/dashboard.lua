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

-- Full art (text + panda, 32 lines) when it fits with the menu, else only the text, else nothing
function M.header()
  local menu = 14 -- items, footer, blank lines, statusline and command line
  if vim.o.lines >= 32 + menu then
    local centered = vim.tbl_map(function(l)
      return M.pad(l) .. l
    end, vim.split(panda, "\n"))
    return text .. "\n" .. table.concat(centered, "\n")
  elseif vim.o.lines >= 9 + menu then
    return text
  end
  return ""
end

return M
