#!/usr/bin/env bash
# Headless smoke test: config loads cleanly, health has no ERROR, code passes lint.
# Usage: scripts/smoke-test.sh   (inside the devShell for stylua/shellcheck: nix develop -c scripts/smoke-test.sh)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NVIM_APPNAME=neopanda
export NEOPANDA_CONFIG="$REPO_DIR" # this tree, not the copy inside npd
NVIM="${NVIM:-nvim}"
command -v npd >/dev/null && [[ "$NVIM" == nvim ]] && NVIM=npd

failures=0
pass() { printf '✅ %s\n' "$*"; }
fail() {
  printf '❌ %s\n' "$*"
  failures=$((failures + 1))
}
skip() { printf '⏭️  %s\n' "$*"; }

result="$(mktemp)"
XDG_STATE_HOME="$(mktemp -d)" # sessions and the remembered theme stay out of the real ones
export XDG_STATE_HOME
trap 'rm -rf "$result" "$XDG_STATE_HOME"' EXIT

# Collects startup errors, errors of the plugins loaded after the UI (lze's DeferredUIEnter, which never fires
# headless) and every ERROR line of the health report. Runs in an empty dir: no session is restored or saved.
(cd "$(mktemp -d)" && "$NVIM" --headless -c "lua (function()
  local out = {}
  if vim.v.errmsg ~= '' then table.insert(out, 'startup: ' .. vim.v.errmsg) end
  local ok, err = pcall(vim.api.nvim_exec_autocmds, 'User', { pattern = 'DeferredUIEnter' })
  if not ok then table.insert(out, 'DeferredUIEnter: ' .. err) end
  local theme, prev = require('pxndxs.theme'), vim.g.colors_name
  local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
  local was, was_glass = theme.transparent, theme.glass
  theme.transparent, theme.glass = true, false
  vim.cmd.colorscheme('michipanda')
  if theme.bg ~= 0x24283b or hl('Normal').bg or not hl('Normal').fg or not hl('NormalFloat').bg or not hl('Visual').bg then
    table.insert(out, 'theme: michipanda or its transparency is wrong')
  end
  theme.glass = true
  vim.cmd.colorscheme('michipanda')
  if hl('NormalFloat').bg or hl('Pmenu').bg or not hl('PmenuSel').bg then
    table.insert(out, 'theme: glass is wrong')
  end
  theme.transparent, theme.glass = was, was_glass
  vim.cmd.colorscheme(prev)
  -- Tab line: many tabs fit, the current one stays visible, same names get their folder
  vim.cmd('edit a/same.lua | tabedit b/same.lua')
  for _ = 1, 40 do vim.cmd('tabnew') end
  vim.cmd('2tabnext')
  local line = vim.api.nvim_eval_statusline(require('pxndxs.tabline').render(), { use_tabline = true, maxwidth = 0 })
  if line.width > vim.o.columns or not line.str:find('b/same.lua', 1, true) or not line.str:find('+', 1, true) then
    table.insert(out, 'tabline: ' .. line.str)
  end
  vim.cmd('tabonly | enew')
  vim.cmd('checkhealth neopanda vim.pack')
  -- Async: the filetype is set when every check is done
  if not vim.wait(30000, function() return vim.bo.filetype == 'checkhealth' end) then
    table.insert(out, 'checkhealth did not finish')
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:find('ERROR') then table.insert(out, line) end
  end
  table.insert(out, 'finished') -- nvim exits 0 when this code aborts: an empty file must not pass
  vim.fn.writefile(out, '$result')
end)()" -c 'qa!' </dev/null >/dev/null 2>&1) || fail "nvim exited with an error" # outside the Lua: quits after an error too

if [[ "$(tail -n 1 "$result")" != finished ]]; then
  fail "the checks did not finish: an error stopped them"
elif [[ "$(wc -l <"$result")" -gt 1 ]]; then
  fail "config / health:"
  sed -e '$d' -e 's/^/   /' "$result"
else
  pass "config loads, health has no ERROR"
fi

syntax_ok=1
for script in "$REPO_DIR"/scripts/*.sh; do
  bash -n "$script" || { fail "bash -n ${script#"$REPO_DIR"/}"; syntax_ok=0; }
done
((syntax_ok)) && pass "bash -n scripts"

if command -v shellcheck >/dev/null; then
  if shellcheck "$REPO_DIR"/scripts/*.sh; then pass "shellcheck"; else fail "shellcheck"; fi
else
  skip "shellcheck not installed"
fi

if command -v stylua >/dev/null; then
  if stylua --check "$REPO_DIR"; then pass "stylua"; else fail "stylua"; fi
else
  skip "stylua not installed"
fi

if ((failures)); then
  printf '\n%d check(s) failed\n' "$failures"
  exit 1
fi
printf '\n🐼 all good\n'
