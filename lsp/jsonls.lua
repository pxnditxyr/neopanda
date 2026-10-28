-- Based on nvim-lspconfig (Apache-2.0)
---@type vim.lsp.Config
return {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  init_options = { provideFormatter = true },
  root_markers = { ".git" },
  settings = { json = { validate = { enable = true } } },
  -- SchemaStore catalog (package.json, tsconfig, …); loaded on first JSON buffer
  before_init = function(_, config)
    local ok, schemastore = pcall(require, "schemastore")
    if ok then
      config.settings.json.schemas = schemastore.json.schemas()
    end
  end,
}
