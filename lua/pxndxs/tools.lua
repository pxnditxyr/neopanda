-- Mason packages, installed only without Nix (the Nix wrapper puts the same tools on PATH).
-- Not here: nixd (Nix only), rust-analyzer (rustup), dartls (Flutter SDK).
local tools = {
  "emmylua_ls",
  "basedpyright",
  "ruff",
  "vtsls",
  "bash-language-server",
  "shellcheck",
  "shfmt",
  "json-lsp",
  "yaml-language-server",
  "taplo",
  "marksman",
  "vue-language-server",
  "svelte-language-server",
  "astro-language-server",
  "html-lsp",
  "css-lsp",
  "tailwindcss-language-server",
  "eslint-lsp",
  "biome",
}

-- Mason builds gopls with `go install`
if vim.fn.executable("go") == 1 then
  table.insert(tools, "gopls")
end

return tools
