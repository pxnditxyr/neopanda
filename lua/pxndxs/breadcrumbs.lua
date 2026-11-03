-- Native breadcrumbs in the winbar: path › file › LSP symbols around the cursor (textDocument/documentSymbol).
-- Only on file windows; without an LSP server it shows the path. Symbol picker: <leader>ss.
local M = {}

local symbols = {} ---@type table<integer, table[]>
local sep = " › "

local function icon(category, name)
  if not package.loaded["mini.icons"] then
    return ""
  end
  local ok, glyph, hl = pcall(MiniIcons.get, category, name)
  return ok and ("%%#%s#%s "):format(hl, glyph) or ""
end

local function escape(s)
  return (s:gsub("%%", "%%%%"))
end

-- Containers only: values (variables, numbers, strings…) would flicker in while passing their line
local kinds = {}
for _, k in ipairs({
  "File",
  "Module",
  "Namespace",
  "Package",
  "Class",
  "Method",
  "Property",
  "Field",
  "Constructor",
  "Enum",
  "Interface",
  "Function",
  "Object",
  "Struct",
}) do
  kinds[vim.lsp.protocol.SymbolKind[k]] = true
end
-- emmylua_ls reports control-flow blocks as modules
local blocks = {}
for _, word in ipairs({ "if", "elseif", "else", "for", "for in", "while", "repeat", "do" }) do
  blocks[word] = true
end

-- Innermost-last chain of symbols whose range contains the cursor (0-based line)
local function chain(list, line, out)
  for _, s in ipairs(list or {}) do
    local range = s.range or (s.location and s.location.range)
    if range and range.start.line <= line and line <= range["end"].line then
      if kinds[s.kind] and not blocks[s.name] then
        table.insert(out, s)
      end
      chain(s.children, line, out)
      break
    end
  end
  return out
end

function M.render()
  local win = vim.g.statusline_winid or vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":~:.")
  local parts = {}
  for dir in vim.fs.dirname(path):gmatch("[^/]+") do
    if dir ~= "." then
      table.insert(parts, "%#WinBarNC#" .. escape(dir))
    end
  end
  table.insert(parts, icon("file", path) .. "%#WinBar#" .. escape(vim.fs.basename(path)))
  local line = vim.api.nvim_win_get_cursor(win)[1] - 1
  for _, s in ipairs(chain(symbols[buf], line, {})) do
    local kind = (vim.lsp.protocol.SymbolKind[s.kind] or ""):lower()
    table.insert(parts, icon("lsp", kind) .. "%#WinBar#" .. escape(s.name))
  end
  return " " .. table.concat(parts, "%#WinBarNC#" .. sep)
end

local function request(buf)
  local client = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/documentSymbol" })[1]
  if not client then
    return
  end
  local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }
  client:request("textDocument/documentSymbol", params, function(err, result)
    if not err and vim.api.nvim_buf_is_valid(buf) then
      symbols[buf] = result or {}
      vim.cmd("redrawstatus!")
    end
  end, buf)
end

local group = vim.api.nvim_create_augroup("pxndxs.breadcrumbs", {})

-- Winbar only on windows showing a real file
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
  group = group,
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    if
      vim.api.nvim_win_get_buf(win) ~= ev.buf or vim.api.nvim_win_get_config(win).relative ~= ""
    then
      return
    end
    local show = vim.bo[ev.buf].buftype == "" and vim.api.nvim_buf_get_name(ev.buf) ~= ""
    vim.wo[win][0].winbar = show and "%{%v:lua.require'pxndxs.breadcrumbs'.render()%}" or ""
  end,
})

local timers = {} ---@type table<integer, uv.uv_timer_t>
vim.api.nvim_create_autocmd({ "LspAttach", "BufEnter", "InsertLeave", "TextChanged" }, {
  group = group,
  callback = function(ev)
    local buf = ev.buf
    timers[buf] = timers[buf] or vim.uv.new_timer()
    timers[buf]:start(
      200,
      0,
      vim.schedule_wrap(function()
        if vim.api.nvim_buf_is_valid(buf) then
          request(buf)
        end
      end)
    )
  end,
})
vim.api.nvim_create_autocmd("CursorMoved", {
  group = group,
  callback = function()
    if vim.wo.winbar ~= "" then
      vim.cmd("redrawstatus") -- current window only
    end
  end,
})
vim.api.nvim_create_autocmd("BufWipeout", {
  group = group,
  callback = function(ev)
    symbols[ev.buf] = nil
    if timers[ev.buf] then
      timers[ev.buf]:close()
      timers[ev.buf] = nil
    end
  end,
})

return M
