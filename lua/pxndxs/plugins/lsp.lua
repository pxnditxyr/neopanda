-- LSP helpers. Servers themselves are native (lsp/*.lua, lua/pxndxs/lsp.lua).
return {
  {
    "SchemaStore.nvim",
    on_require = "schemastore", -- lsp/jsonls.lua requires it
  },
  {
    "plenary.nvim",
    dep_of = { "flutter-tools.nvim", "neotest" }, -- neotest-golang and neotest-dart need it
  },
  {
    "flutter-tools.nvim",
    ft = "dart",
    after = function()
      -- Starts dartls itself from the Flutter SDK on PATH; the debugger registers the Dart/Flutter
      -- adapters with nvim-dap (:FlutterRun then runs under it, breakpoints work)
      require("flutter-tools").setup({ debugger = { enabled = true } })
    end,
  },
}
