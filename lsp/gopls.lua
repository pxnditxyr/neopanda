-- Based on nvim-lspconfig (Apache-2.0)
-- shortcut: jumping into the stdlib or module cache starts a second gopls; reuse the client if it gets noisy
---@type vim.lsp.Config
return {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { { "go.work" }, { "go.mod" }, { ".git" } },
  settings = {
    gopls = {
      semanticTokens = true,
      gofumpt = true,
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}
