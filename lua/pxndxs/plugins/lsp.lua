-- LSP helpers. Servers themselves are native (lsp/*.lua, lua/pxndxs/lsp.lua).
return {
  {
    "SchemaStore.nvim",
    on_require = "schemastore", -- lsp/jsonls.lua requires it
  },
  {
    "plenary.nvim",
    dep_of = "flutter-tools.nvim",
  },
  {
    "flutter-tools.nvim",
    ft = "dart",
    after = function()
      -- Starts dartls itself from the Flutter SDK on PATH
      require("flutter-tools").setup({})
    end,
  },
}
