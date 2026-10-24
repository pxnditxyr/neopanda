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

---@type vim.lsp.Config
return {
  cmd = { "vtsls", "--stdio" },
  init_options = { hostInfo = "neovim" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  settings = {
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
