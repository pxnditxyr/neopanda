-- Based on nvim-lspconfig (Apache-2.0)
---@type vim.lsp.Config
return {
  cmd = { "emmylua_ls" },
  filetypes = { "lua" },
  root_markers = {
    { ".emmyrc.json", ".emmyrc.lua", ".luarc.json", ".luarc.jsonc" },
    { ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
    { ".git" },
  },
  workspace_required = false,
  settings = {
    emmylua = {
      codeLens = { enable = true },
      hint = { enable = true },
    },
  },
}
