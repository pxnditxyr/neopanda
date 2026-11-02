# neopanda 🐼

A Neovim **nightly (0.13)** config built only on native features: LSP without nvim-lspconfig,
treesitter, diagnostics, ui2, undotree, difftool and `vim.pack` — no third-party plugins yet.
Keymaps are designed for a **Dvorak** layout.

It runs as its own app (`NVIM_APPNAME=neopanda`), so it never touches an existing `~/.config/nvim`.
Start it with `npd` (or `neopanda`).

## Install

### Nix + home-manager (macOS / NixOS)

Add the flake as an input and enable the module. The config dir is a symlink to your clone, so
`vim.pack` can write its lockfile and Lua edits apply without a rebuild.

```nix
# flake.nix
inputs.neopanda.url = "github:pxnditxyr/neopanda";

# home-manager
imports = [ inputs.neopanda.homeModules.default ];
programs.neopanda = {
  enable = true;
  configPath = "${config.home.homeDirectory}/dev/neopanda"; # your clone
};
```

The `npd` wrapper puts everything the config needs on `PATH`: git, ripgrep, fd and the LSP servers.

### Ubuntu / WSL2 (no Nix)

```sh
git clone https://github.com/pxnditxyr/neopanda ~/dev/neopanda
~/dev/neopanda/scripts/bootstrap.sh --dry-run   # preview
~/dev/neopanda/scripts/bootstrap.sh
```

The script is safe to re-run. It:

- installs `git ripgrep fd-find build-essential curl unzip xz-utils xclip inotify-tools` with apt and links `fd` → `fdfind`;
- installs [bob](https://github.com/MordechaiHadad/bob) from a checksum-verified release, then Neovim nightly;
- keeps Node 22+ if present, else installs a checksum-verified Node 26 into `~/.local` (Mason needs it);
- moves an existing `~/.config/neopanda` (and its data, state and cache) to `*.bak.<timestamp>`;
- links `~/.config/neopanda` to the clone;
- adds `PATH` and `alias npd='NVIM_APPNAME=neopanda nvim'` to `~/.bashrc` / `~/.zshrc`.

LSP servers are not installed on this path yet; `:checkhealth neopanda` lists the missing ones.
On WSL2 the clipboard works through WSLg with `xclip`.

### Uninstall

```sh
rm -rf ~/.config/neopanda ~/.local/share/neopanda ~/.local/state/neopanda ~/.cache/neopanda
```

Then remove the `# neopanda` block from your shell rc (bootstrap) or the module (home-manager).

## Settings

Per-machine overrides go in `lua/pxndxs/settings_local.lua` (gitignored), merged over the defaults:

```lua
return {
  ui2 = true,        -- experimental message/cmdline UI
  autoformat = true, -- format on save (toggle: <leader>uf, buffer: <leader>uF)
  nerd_font = true,  -- icons in diagnostic signs and the completion menu; false = plain text
}
```

## Keymaps

Leader is `<Space>`. Only maps that nightly doesn't already provide (`gr*`, `]d`, `]q`, `an`/`in`, `al`/`il`, `ZR`, …).

| Keys | Mode | Action |
|---|---|---|
| `<Esc>` | n | Clear search highlight |
| `n` / `N` | n | Next / previous match, centered |
| `gs` / `gS` | n x o | Next / previous misspelled word (`]s`/`[s` are awkward on Dvorak) |
| `J` | n | Join lines keeping the cursor |
| `<` / `>` | x | Indent and keep the selection |
| `<A-j>` / `<A-k>` | n x | Move line / selection down / up |
| `<leader>w` / `<leader>z` | n | Write / close window |
| `<C-h>` `<C-j>` `<C-k>` | n | Go to window left / down / up (`<C-l>` stays native: redraw, clears multicursors) |
| `<C-Arrows>` | n | Resize window |
| `<leader>tn` | n | New tab (`gt`/`gT` to switch) |
| `<leader>uu` | n | Toggle undotree |
| `<leader>ud` / `<leader>uv` | n | Toggle diagnostics / diagnostic virtual lines |
| `gd` / `gD` | n | LSP definition / declaration |
| `<leader>uh` | n | Toggle inlay hints (LSP) |
| `<leader>uS` | n | Toggle snippets in the completion menu |
| `<leader>lr` / `<leader>li` | n | LSP restart / info (`:checkhealth vim.lsp`) |
| `<C-t>` / `<C-d>` | i s | Snippet: next / previous field (outside a snippet: native indent / dedent) |
| `ys{motion}{char}` / `yss` / `S` | n / n / x | Surround: add (motion / line / selection) |
| `ds{char}` / `cs{old}{new}` | n | Surround: delete / replace |
| `s` / `S` | n x o / n o | Flash jump / treesitter selection (`r` in operator-pending: remote) |
| `-` / `_` | n | Parent directory (native browser) / edit it with oil (rename, create, delete) |
| `<leader>sr` | n x | Search and replace in the project (grug-far) |
| `<leader><leader>` / `<leader>ff` | n | Find files (mini.pick) |
| `<leader>fr` / `<leader>fb` | n | Recent files / buffers |
| `<leader>sg` / `<leader>sw` / `<leader>sb` | n | Grep live / word under cursor / lines in buffers |
| `<leader>ss` / `<leader>sS` | n | LSP symbols in file / workspace |
| `<leader>sd` / `<leader>sh` / `<leader>sk` / `<leader>sR` | n | Diagnostics / help / keymaps / resume last picker |
| `<leader>qs` / `<leader>qS` / `<leader>ql` | n | Session: restore (cwd) / pick / last |
| `<leader>qd` / `<leader>qq` | n | Session: don't save on exit / quit all |

Native multicursor (0.13): `Q` adds/removes a cursor, `zq{motion}` one at every target (`zqgn` = every match),
`<C-l>` clears, `gQ` restores. mini.ai adds `a`/`i` objects for brackets, quotes, tags and `?` that also reach
the next match; `af`/`ac`/`aa` (function, class, argument) come from treesitter; visual `an`/`in` stay native.
`TODO` `FIXME` `HACK` `NOTE` and `#rrggbb` are highlighted (LSP colors in CSS/Tailwind are native).

Useful native commands: `:Undotree`, `:DiffTool {left} {right}` (files or directories), `:Cfilter`,
`ZR` (restart keeping the session).

## LSP

Server configs are self-contained in `lsp/*.lua` and only enabled when their binary is on `PATH`:
emmylua_ls, nixd, vtsls, basedpyright, ruff, bashls, jsonls, yamlls, taplo, marksman, rust_analyzer, gopls,
vue_ls, svelte, astro, html, cssls, tailwindcss, eslint, biome. tailwindcss, eslint and biome start only in
projects that use them. Dart/Flutter: flutter-tools.nvim starts dartls from the Flutter SDK on `PATH`.
Off Nix, rust-analyzer comes from `rustup component add rust-analyzer`.
On Linux, servers learn about new files through `inotifywait`: keep WSL projects under `~` (not `/mnt/c`), and
raise `fs.inotify.max_user_watches` with sysctl if you see "no space left on device".

Saving formats through the buffer's LSP server (one per buffer: biome when the project has `biome.json`).
`<leader>uf` toggles format on save, `<leader>uF` only for the current buffer. Markdown is not formatted.

## Completion

Native: the menu opens while typing (`'autocomplete'`), also in the command line for `:`, `/` and `?`.
`<C-y>` accepts, `<C-e>` cancels, `<C-s>` shows the signature. The signature also pops up above the cursor
after `(` and `,` and stays while the cursor is inside the call. Servers are asked after a letter or one
of their trigger characters (`.`, `"` / `/` in imports…), not after `)`, `=`, `(`, `,` or a space.
Snippets come from friendly-snippets and `snippets/` (VS Code JSON, one file per language), served by
mini.snippets as an LSP server (framework snippets such as Angular stay off). They are ranked with the
rest (a server item wins a tie); `<leader>uS` hides them. Jump with `<Tab>`/`<S-Tab>` or `<C-t>`/`<C-d>`.

## UI

catppuccin (mocha) with integrations detected from the installed plugins. Native, no plugin: the statusline
(mode, git, file, LSP progress, diagnostics, position; `lua/pxndxs/statusline.lua`), breadcrumbs in the winbar
(path › file › LSP symbols around the cursor; `lua/pxndxs/breadcrumbs.lua`), ui2 messages and LSP/treesitter
folds (`za`, `zc`, `zo`, `zM`, `zR`). mini.icons (also for plugins asking nvim-web-devicons), mini.indentscope
(current scope line), render-markdown in markdown, mini.pick as picker and `vim.ui.select` (`z=`, `:tselect`…).

## Sessions

Native (`:mksession`), no plugin. Quitting saves the session of the cwd (one per git branch other than
main/master) in `stdpath("state")/sessions/`; starting `npd` with no file restores it. `npd file`, stdin and
`ZR` (`:restart`, which keeps its own session) neither restore nor save one. Special windows (help,
terminal, oil, grug-far) are left out, and nothing is saved when no file is open.

## Plugins (vim.pack)

Plugins are pinned in `nvim-pack-lock.json`, created with the first plugin — commit it.

| Task | How |
|---|---|
| Update | `:packupdate` → review → `:w` to apply, `:q` to cancel → commit the lockfile |
| Revert | `git checkout -- nvim-pack-lock.json`, then `:packupdate ++lockfile` |
| Remove | Delete the spec in `lua/pxndxs/pack.lua`, `ZR`, `:packdel ++all` |
| New machine | Clone and start `npd`: locked revisions install on first launch |

Build steps (e.g. `:TSUpdate`) go in the `build` table of `lua/pxndxs/pack.lua`.

## Health and tests

- `:checkhealth neopanda` — Neovim version, environment, settings, tools, LSP servers and plugin state.
- `nix develop -c scripts/smoke-test.sh` — headless load, health errors, `bash -n`, shellcheck and stylua; exits non-zero on failure.
- `.github/workflows/ci.yml` — the same checks plus the Ubuntu bootstrap. Manual only (Actions → CI → Run workflow).

## Development

```sh
nix develop          # stylua, shellcheck, lua-language-server, nixd
nix flake check
nix build            # ./result/bin/npd
```

`lsp/*.lua` files are based on [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) (Apache-2.0).
