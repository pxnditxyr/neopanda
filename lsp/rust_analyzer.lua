-- Based on nvim-lspconfig (Apache-2.0)
---@type vim.lsp.Config
return {
  cmd = { "rust-analyzer" },
  filetypes = { "rust" },
  -- Workspace Cargo.toml wins over a member crate's
  root_markers = { { "Cargo.lock", "rust-project.json" }, { "Cargo.toml" }, { ".git" } },
  capabilities = {
    experimental = { serverStatusNotification = true },
  },
  settings = {
    ["rust-analyzer"] = {
      check = { command = "clippy" },
      lens = { references = { method = { enable = true } } },
    },
  },
}
