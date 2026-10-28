-- Based on nvim-lspconfig (Apache-2.0). Vue, Svelte and Astro left out: Biome support there is experimental.
---@type vim.lsp.Config
return {
  cmd = { "biome", "lsp-proxy" },
  filetypes = {
    "css",
    "graphql",
    "javascript",
    "javascriptreact",
    "json",
    "jsonc",
    "typescript",
    "typescriptreact",
  },
  -- Only where the project has a Biome config
  root_dir = function(bufnr, on_dir)
    local config_root = vim.fs.root(bufnr, { "biome.json", "biome.jsonc" })
    if config_root then
      local locks =
        { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock", "deno.lock" }
      on_dir(vim.fs.root(bufnr, { locks, { ".git" } }) or config_root)
    end
  end,
}
