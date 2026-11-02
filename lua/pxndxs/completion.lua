-- Native completion extras. Options live in options.lua, LSP completion in lsp.lua,
-- snippets (mini.snippets as an in-process LSP server) in plugins/completion.lua.
local M = {}

-- Cmdline autocompletion for : / ?
vim.api.nvim_create_autocmd("CmdlineChanged", {
  group = vim.api.nvim_create_augroup("pxndxs.cmdline_complete", {}),
  pattern = { ":", "/", "?" },
  desc = "Cmdline autocompletion",
  callback = function()
    vim.fn.wildtrigger()
  end,
})
-- <Up>/<Down> keep browsing history while the menu is open
for _, key in ipairs({ "<Up>", "<Down>" }) do
  vim.keymap.set("c", key, function()
    return vim.fn.wildmenumode() == 1 and "<C-e>" .. key or key
  end, { expr = true, desc = "History " .. key })
end

-- Snippet jumps on the Dvorak right-hand home row (<Tab>/<S-Tab> also work, native).
-- Outside a snippet the keys keep their native job: <C-t> indent, <C-d> dedent.
local function jump(direction, key)
  return function()
    if vim.snippet.active({ direction = direction }) then
      return ("<Cmd>lua vim.snippet.jump(%d)<CR>"):format(direction)
    end
    return key
  end
end
vim.keymap.set(
  { "i", "s" },
  "<C-t>",
  jump(1, "<C-t>"),
  { expr = true, desc = "Snippet: next field" }
)
vim.keymap.set(
  { "i", "s" },
  "<C-d>",
  jump(-1, "<C-d>"),
  { expr = true, desc = "Snippet: previous field" }
)

-- Kind icons (codicons) in the completion menu; without a Nerd Font the kind names stay
local icons = {
  Text = "\u{ea93}",
  Method = "\u{ea8c}",
  Function = "\u{eabe}",
  Constructor = "\u{eaf8}",
  Field = "\u{eb5f}",
  Variable = "\u{ea88}",
  Class = "\u{eb5b}",
  Interface = "\u{eb61}",
  Module = "\u{ea8b}",
  Property = "\u{eb65}",
  Unit = "\u{ea96}",
  Value = "\u{eaac}",
  Enum = "\u{ea95}",
  Keyword = "\u{eb62}",
  Snippet = "\u{eb66}",
  File = "\u{eb60}",
  Reference = "\u{eb36}",
  Folder = "\u{ea83}",
  EnumMember = "\u{eb5e}",
  Constant = "\u{eb5d}",
  Struct = "\u{ea91}",
  Event = "\u{ea86}",
  Operator = "\u{eb64}",
  TypeParameter = "\u{ea92}",
}

local nerd_font = require("pxndxs.settings").nerd_font

---@param item lsp.CompletionItem
---@return table
function M.convert(item)
  local res = {}
  -- Color keeps its native swatch
  local kind = vim.lsp.protocol.CompletionItemKind[item.kind]
  if nerd_font and icons[kind] then
    res.kind = icons[kind] .. " " .. kind
  end
  -- Vim refilters the menu by `word` while typing, so match snippets by their name, not their body.
  -- The snippet is still expanded from its body.
  if kind == "Snippet" then
    res.word = item.label
  end
  return res
end

-- Results of all servers ranked together (natively each server's list is appended after the other's,
-- so snippets landed below every vtsls item). On a tie, server items go before snippets.
local snippet = vim.lsp.protocol.CompletionItemKind.Snippet
local function lsp_item(item)
  return vim.tbl_get(item, "user_data", "nvim", "lsp", "completion_item") or {}
end
function M.cmp(a, b)
  local sa, sb = a._fuzzy_score or 0, b._fuzzy_score or 0
  if sa ~= sb then
    return sa > sb
  end
  local la, lb = lsp_item(a), lsp_item(b)
  if (la.kind == snippet) ~= (lb.kind == snippet) then
    return lb.kind == snippet
  end
  return (la.sortText or la.label or a.word) < (lb.sortText or lb.label or b.word)
end

-- 'autocomplete' calls this after every typed char. Like the LSP spec (and blink.cmp, nvim-cmp, VS Code),
-- ask the servers only after a keyword char, or after one of a server's trigger characters, telling it
-- which one (`"` in an import → paths). Whitespace never triggers. After `)`, `=`, `"a"`… nothing, else
-- servers answer with every symbol. Cost: <C-x><C-o> there shows nothing either (type a letter first).
function M.omnifunc(findstart, base)
  if findstart == 0 then
    return vim.lsp.omnifunc(findstart, base)
  end
  local before = vim.api.nvim_get_current_line():sub(1, vim.fn.col(".") - 1)
  if vim.fn.match(before, [[\k$]]) >= 0 then
    return vim.lsp.omnifunc(findstart, base)
  end
  local char = before:sub(-1)
  if char:match("^%S$") then
    local ids = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, method = "textDocument/completion" })) do
      local triggers =
        vim.tbl_get(client.server_capabilities, "completionProvider", "triggerCharacters")
      if triggers and vim.list_contains(triggers, char) then
        table.insert(ids, client.id)
      end
    end
    if #ids > 0 then
      vim.lsp.completion.get({ ctx = { triggerKind = 2, triggerCharacter = char }, client_id = ids })
      return -2 -- the menu opens when the servers answer, as with vim.lsp.omnifunc
    end
  end
  return -3
end

-- Snippets in the menu, toggled with <leader>uS (read by the mini.snippets server)
M.snippets = true
vim.keymap.set("n", "<leader>uS", function()
  M.snippets = not M.snippets
  vim.notify("Snippets in menu: " .. (M.snippets and "on" or "off"))
end, { desc = "Toggle snippets in menu" })

-- SQL buffers (plugins/lang.lua): dadbod's tables, columns and functions before its reserved words
function M.dadbod(findstart, base)
  local res = vim.fn["vim_dadbod_completion#omni"](findstart, base)
  if findstart == 1 or type(res) ~= "table" then
    return res
  end
  local items, reserved = {}, {}
  for _, item in ipairs(res.words or res) do
    table.insert(type(item) == "table" and item.kind == "R" and reserved or items, item)
  end
  return vim.list_extend(items, reserved)
end

return M
