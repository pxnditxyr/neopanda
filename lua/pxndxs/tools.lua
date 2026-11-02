-- Mason packages, installed only without Nix (the Nix wrapper puts the same tools on PATH).
-- Not here: nixd (Nix only), rust-analyzer (rustup), dartls and the Dart debugger (Flutter SDK).
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
  "copilot-language-server",
  "js-debug-adapter",
  "codelldb",
}

-- Mason builds gopls and delve with `go install`
if vim.fn.executable("go") == 1 then
  vim.list_extend(tools, { "gopls", "delve" })
end

return tools
