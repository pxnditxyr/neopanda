-- Based on nvim-lspconfig (Apache-2.0)

-- The server only sends inlay hints when enabled here (<leader>uh toggles their display)
local inlay_hints = {
  parameterNames = { enabled = "literals" },
  parameterTypes = { enabled = true },
  variableTypes = { enabled = true },
  propertyDeclarationTypes = { enabled = true },
  functionLikeReturnTypes = { enabled = true },
  enumMemberValues = { enabled = true },
}

-- @vue/typescript-plugin from vue-language-server: the Nix wrapper exports its path, Mason keeps it in its package
local vue_plugin = vim.env.NEOPANDA_VUE_LS
  or vim.fn.stdpath("data")
    .. "/mason/packages/vue-language-server/node_modules/@vue/language-server"

---@type vim.lsp.Config
return {
  cmd = { "vtsls", "--stdio" },
  init_options = { hostInfo = "neovim" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
  settings = {
    vtsls = {
      tsserver = {
        globalPlugins = {
          {
            name = "@vue/typescript-plugin",
            location = vue_plugin,
            languages = { "vue" },
            configNamespace = "typescript",
          },
        },
      },
    },
    typescript = { inlayHints = inlay_hints },
    javascript = { inlayHints = inlay_hints },
  },
  -- Root at the package-manager lockfile; leave Deno projects to denols
  root_dir = function(bufnr, on_dir)
    local locks = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
    local project_root = vim.fs.root(bufnr, { locks, { ".git" } })
    local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" })
    if deno_root and (not project_root or #deno_root >= #project_root) then
      return
    end
    on_dir(project_root or vim.fn.getcwd())
  end,
}
