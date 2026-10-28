-- Based on nvim-lspconfig (Apache-2.0)
local configs =
  { "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs", "tailwind.config.ts" }

---@type vim.lsp.Config
return {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html",
    "css",
    "scss",
    "postcss",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
    "markdown",
    "mdx",
  },
  capabilities = {
    workspace = { didChangeWatchedFiles = { dynamicRegistration = true } },
  },
  settings = {
    tailwindCSS = {
      validate = true,
      classAttributes = { "class", "className", "class:list", "classList", "ngClass" },
    },
  },
  -- Only in Tailwind projects: a v3 config file, or tailwindcss in package.json (v4 has no config)
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, configs)
    if not root then
      local pkg =
        vim.fs.find("package.json", { path = vim.api.nvim_buf_get_name(bufnr), upward = true })[1]
      local file = pkg and io.open(pkg)
      if file then
        if file:read("*a"):find('"tailwindcss"', 1, true) then
          root = vim.fs.dirname(pkg)
        end
        file:close()
      end
    end
    if root then
      on_dir(root)
    end
  end,
}
