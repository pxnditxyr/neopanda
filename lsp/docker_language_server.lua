-- Based on nvim-lspconfig (Apache-2.0)
-- Dockerfile, Compose (filetype yaml.docker-compose, set in lua/pxndxs/lsp.lua) and Bake files
---@type vim.lsp.Config
return {
  cmd = { "docker-language-server", "start", "--stdio" },
  filetypes = { "dockerfile", "yaml.docker-compose", "hcl.docker-bake" },
  get_language_id = function(_, ft)
    return ft == "yaml.docker-compose" and "dockercompose"
      or ft == "hcl.docker-bake" and "dockerbake"
      or ft
  end,
  root_markers = {
    "Dockerfile",
    "docker-compose.yaml",
    "docker-compose.yml",
    "compose.yaml",
    "compose.yml",
    "docker-bake.json",
    "docker-bake.hcl",
  },
}
