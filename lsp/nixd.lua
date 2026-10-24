-- Based on nvim-lspconfig (Apache-2.0)
-- Option completion comes from the flake in $NIXD_FLAKE (default /etc/nixos) and the hostname.
local flake = vim.env.NIXD_FLAKE or "/etc/nixos"
local host = vim.fn.hostname():gsub("%..*$", "")
local user = vim.env.USER or ""
local get = ('(builtins.getFlake "%s")'):format(flake)

---@type vim.lsp.Config
return {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", ".git" },
  settings = {
    nixd = {
      nixpkgs = { expr = "import <nixpkgs> { }" },
      formatting = { command = { "nixfmt" } },
      options = {
        nixos = { expr = ("%s.nixosConfigurations.%s.options"):format(get, host) },
        darwin = { expr = ("%s.darwinConfigurations.%s.options"):format(get, host) },
        home_manager = {
          expr = ('%s.homeConfigurations."%s@%s".options'):format(get, user, host),
        },
      },
    },
  },
}
