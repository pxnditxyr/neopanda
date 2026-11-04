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
              sqls # SQL
              docker-language-server # Dockerfile / Compose / Bake
              # Languages (plugins/lang.lua)
              hurl # .hurl requests (hurl.nvim)
              jq # hurl.nvim JSON formatting
              postgresql # psql for dadbod
              sqlite # sqlite3 for dadbod
              mariadb.client # mysql for dadbod
              # html, cssls and eslint come from vscode-langservers-extracted
              # dartls comes from the project's Flutter SDK (flutter-tools.nvim)
            ]
            ++ lib.optionals stdenv.hostPlatform.isLinux [
              inotify-tools # LSP file watching (inotifywait backend)
              lldb # Rust debug adapter (lldb-dap); macOS uses Xcode's
            ];
          # The config npd runs. Only what Neovim reads, so docs and scripts don't rebuild it.
          config = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./init.lua
              ./lua
              ./lsp
              ./nvim-pack-lock.json
            ];
          };
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
                    --set-default NEOPANDA_CONFIG ${config} \
                    --add-flags '-u "$NEOPANDA_CONFIG/init.lua"' \
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
    };
}
