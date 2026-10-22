# neopanda 🐼

Neovim nightly config built on vim.pack. Work in progress.

## Usage

```sh
nix build              # → ./result/bin/npd
nix flake check
stylua --check .
```

`npd` and `neopanda` run with `NVIM_APPNAME=neopanda`, so they read `~/.config/neopanda`.
