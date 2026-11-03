-- Based on nvim-lspconfig (Apache-2.0)
---@type vim.lsp.Config
return {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
  settings = {
    redhat = { telemetry = { enabled = false } },
    yaml = { format = { enable = true } },
  },
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = true
  end,
}
