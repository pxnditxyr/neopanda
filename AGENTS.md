# AGENTS.md

## Conventions
- Everything in English: code, comments, docs.
- Plugins are managed only by vim.pack; never add plugins through Nix.
- Lua namespace: `pxndxs` (config modules), `neopanda` (health).
- Unstable nightly APIs go behind `pcall` or `vim.fn.has("nvim-0.13")`.

## Gotchas
- `NVIM_APPNAME=neopanda`, and the running config is `require("pxndxs.env").config`: the Nix store (read-only) under `npd`, a clone with `NEOPANDA_CONFIG=<path>`, `stdpath("config")` without Nix. Never assume it is writable or use `stdpath("config")` to find its files.
- `nvim-pack-lock.json` is written by vim.pack; never edit it by hand. With a read-only config, vim.pack writes a copy in `stdpath("state")` (`'packlockfile'`, set in `lua/pxndxs/pack.lua` before the first vim.pack call).
- Lines marked `-- DEV:` are dev-only notes, stripped on stage by a local git filter; keep that marker for TODO-style notes.
- `pxndxs.env` holds detected facts (read-only); `pxndxs.settings` holds toggles, overridden per machine by the gitignored `lua/pxndxs/settings_local.lua`.
- The author types Dvorak US: avoid maps where `[`/`]` (right pinky, number row) is followed by another right-pinky key (`s`, `l`, `z`, `-`, `/`); prefer aliases like `gs`/`gS` for `]s`/`[s`.
