-- Native statuscolumn: other signs (diagnostics…) │ number │ git signs, like Helix and LazyVim. With one
-- shared sign column, diagnostics (higher priority) hid the git marks.
local M = {}

---@param mark? vim.api.keyset.extmark_details
local function sign(mark)
  return mark and ("%%#%s#%s%%*"):format(mark.sign_hl_group or "SignColumn", mark.sign_text) or "  "
end

function M.render()
  local win = vim.g.statusline_winid
  if not (vim.wo[win].number or vim.wo[win].relativenumber) then
    return ""
  end
  local git, other
  if vim.v.virtnum == 0 then
    local row = vim.v.lnum - 1
    local buf = vim.api.nvim_win_get_buf(win)
    local marks = vim.api.nvim_buf_get_extmarks(buf, -1, { row, 0 }, { row, -1 }, {
      details = true,
      type = "sign",
    })
    for _, m in ipairs(marks) do
      local d = m[4] --[[@as vim.api.keyset.extmark_details]]
      if d.sign_text then
        if (d.sign_hl_group or ""):find("^GitSigns") then
          git = (not git or d.priority > git.priority) and d or git
        else
          other = (not other or d.priority > other.priority) and d or other
        end
      end
    end
  end
  -- %l keeps the native number column (relative numbers, CursorLineNr, diagnostic numhl)
  return sign(other) .. "%l " .. sign(git)
end

vim.o.statuscolumn = "%!v:lua.require'pxndxs.statuscolumn'.render()"

return M
