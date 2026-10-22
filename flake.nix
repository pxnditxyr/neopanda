{
  description = "neopanda 🐼 — Neovim nightly with vim.pack";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  nixConfig = {
    extra-substituters = [ "https://nix-community.cachix.org" ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    { nixpkgs, neovim-nightly-overlay, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          neovim = neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
          # Only exposes npd and neopanda; never shadows a system `nvim`.
          neopanda =
            pkgs.runCommand "neopanda"
              {
                nativeBuildInputs = [ pkgs.makeWrapper ];
                meta.mainProgram = "npd";
              }
              ''
                for name in npd neopanda; do
                  makeWrapper ${neovim}/bin/nvim $out/bin/$name \
                    --set-default NVIM_APPNAME neopanda \
                    --set NEOPANDA_NIX 1
                done
              '';
        in
        {
          inherit neopanda;
          default = neopanda;
        }
      );
    };
}
