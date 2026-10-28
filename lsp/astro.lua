-- Based on nvim-lspconfig (Apache-2.0)
---@type vim.lsp.Config
return {
  cmd = { "astro-ls", "--stdio" },
  filetypes = { "astro" },
  root_markers = { "package.json", "tsconfig.json", "jsconfig.json", ".git" },
  init_options = { typescript = {} },
  -- The server uses the project's TypeScript
  before_init = function(_, config)
    local dirs =
      vim.fs.find("node_modules", { path = config.root_dir, upward = true, limit = math.huge })
    for _, dir in ipairs(dirs) do
      local lib = dir .. "/typescript/lib"
      if vim.uv.fs_stat(lib) then
        config.init_options.typescript.tsdk = lib
        return
      end
    end
  end,
}
