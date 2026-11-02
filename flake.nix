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
    {
      self,
      nixpkgs,
      neovim-nightly-overlay,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              # Copilot's language server is unfree; nothing else is
              config.allowUnfreePredicate = pkg: nixpkgs.lib.getName pkg == "copilot-language-server";
            }
          )
        );
    in
    {
      packages = forAllSystems (
        pkgs:
        let
          neovim = neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.neovim;
          # Tools used by native features. Prefixed so the Nix versions always win.
          tools =
            with pkgs;
            [
              git # vim.pack
              ripgrep # 'grepprg'
              fd # 'findfunc'
              lazygit # <leader>gg
              copilot-language-server # lsp/copilot.lua (AI suggestions)
              tree-sitter # nvim-treesitter parser builds
              stdenv.cc # C compiler for parsers
              # LSP servers (lsp/*.lua)
              emmylua-ls # Lua
              nixd # Nix
              nixfmt # nixd formatting
              vtsls # TypeScript / JavaScript
              basedpyright # Python types
              ruff # Python lint / format
              bash-language-server # Shell
              shellcheck # bashls diagnostics
              shfmt # bashls formatting
              vscode-langservers-extracted # JSON
              yaml-language-server # YAML
              taplo # TOML
              marksman # Markdown
              rust-analyzer # Rust
              gopls # Go
              vue-language-server # Vue (+ @vue/typescript-plugin for vtsls)
              svelte-language-server # Svelte
              astro-language-server # Astro
              tailwindcss-language-server # Tailwind classes
              biome # JS/TS/JSON lint + format (projects with biome.json)
              # Debug adapters (plugins/debug.lua)
              vscode-js-debug # JS/TS (js-debug)
              delve # Go (dlv)
              # html, cssls and eslint come from vscode-langservers-extracted
              # dartls comes from the project's Flutter SDK (flutter-tools.nvim)
            ]
            ++ lib.optionals stdenv.hostPlatform.isLinux [
              inotify-tools # LSP file watching (inotifywait backend)
              lldb # Rust debug adapter (lldb-dap); macOS uses Xcode's
            ];
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
                    --set NEOPANDA_NIX 1 \
                    --set NEOPANDA_VUE_LS ${pkgs.vue-language-server}/lib/language-tools/packages/language-server \
                    --prefix PATH : ${pkgs.lib.makeBinPath tools}
                done
              '';
        in
        {
          inherit neopanda;
          default = neopanda;
        }
      );

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            stylua
            shellcheck
            lua-language-server
            nixd
          ];
        };
      });

      homeModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.neopanda;
        in
        {
          options.programs.neopanda = {
            enable = lib.mkEnableOption "neopanda";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
              defaultText = lib.literalExpression "neopanda.packages.\${system}.default";
              description = "The neopanda package providing `npd` and `neopanda`.";
            };
            configPath = lib.mkOption {
              type = lib.types.str;
              example = lib.literalExpression ''"''${config.home.homeDirectory}/src/neopanda"'';
              description = "Absolute path to the neopanda checkout, symlinked as ~/.config/neopanda so vim.pack can write its lockfile.";
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
            xdg.configFile."neopanda".source = config.lib.file.mkOutOfStoreSymlink cfg.configPath;
          };
        };
    };
}
