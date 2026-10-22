# AGENTS.md

## Conventions
- Everything in English: code, comments, docs.
- Plugins are managed only by vim.pack; never add plugins through Nix.
- Lua namespace: `pxndxs` (config modules), `neopanda` (health).
- Unstable nightly APIs go behind `pcall` or `vim.fn.has("nvim-0.13")`.

## Gotchas
- `NVIM_APPNAME=neopanda`: config is `stdpath("config")`, not `~/.config/nvim`.
- `nvim-pack-lock.json` is written by vim.pack; never edit it by hand.
- Lines marked `-- DEV:` are dev-only notes, stripped on stage by a local git filter; keep that marker for TODO-style notes.
- `pxndxs.env` holds detected facts (read-only); `pxndxs.settings` holds toggles, overridden per machine by the gitignored `lua/pxndxs/settings_local.lua`.
