-- Native LSP. Server configs live in lsp/*.lua. Defaults kept: gra grn grr gri grt grx gO K
-- <C-S>, <C-]> (definition via tagfunc), gq (formatexpr), document colors.
local autocmd = vim.api.nvim_create_autocmd

autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("pxndxs.lsp", {}),
  desc = "LSP buffer setup",
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buf = buf, desc = "LSP: " .. desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("gD", vim.lsp.buf.declaration, "Go to declaration")
    map("<leader>lr", "<Cmd>lsp restart<CR>", "Restart")
    map("<leader>li", "<Cmd>checkhealth vim.lsp<CR>", "Info")
    map("<leader>uh", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle inlay hints")

    -- 'autocomplete' triggers the menu; this adds snippets, auto-imports and the resolve popup
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, buf, { autotrigger = false })
    end

    -- LSP folding for the window showing this buffer (overrides treesitter folding)
    if client:supports_method("textDocument/foldingRange") then
      local win = vim.api.nvim_get_current_win()
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.wo[win][0].foldmethod = "expr"
        vim.wo[win][0].foldexpr = "v:lua.vim.lsp.foldexpr()"
      end
    end

    -- Highlight references of the symbol under the cursor
    if client:supports_method("textDocument/documentHighlight") then
      local group = vim.api.nvim_create_augroup("pxndxs.lsp_highlight." .. buf, {})
      autocmd({ "CursorHold", "CursorHoldI" }, {
        group = group,
        buf = buf,
        callback = vim.lsp.buf.document_highlight,
      })
      autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        buf = buf,
        callback = vim.lsp.buf.clear_references,
      })
      autocmd("LspDetach", {
        group = group,
        buf = buf,
        callback = function()
          vim.lsp.buf.clear_references()
          vim.api.nvim_del_augroup_by_id(group)
        end,
      })
    end
  end,
})

-- Opt-in features, active for every client that supports them
-- Linked editing stays off: it loses the tag pair once `ciw` empties the name; nvim-ts-autotag renames tags
vim.lsp.codelens.enable(true)
vim.lsp.on_type_formatting.enable(true)

vim.lsp.config("*", { root_markers = { ".git" } })

-- Without Nix, servers come from Mason: its bin must be on PATH before the check below
if not require("pxndxs.env").is_nix then
  vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH
end

-- Enable only the servers whose binary is installed
local servers = {
  "emmylua_ls",
  "nixd",
  "vtsls",
  "basedpyright",
  "ruff",
  "bashls",
  "jsonls",
  "yamlls",
  "taplo",
  "marksman",
}
for _, name in ipairs(servers) do
  local cmd = (vim.lsp.config[name] or {}).cmd
  if type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1 then
    vim.lsp.enable(name)
  end
end
