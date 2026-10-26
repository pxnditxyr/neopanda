#!/usr/bin/env bash
# Headless smoke test: config loads cleanly, health has no ERROR, code passes lint.
# Usage: scripts/smoke-test.sh   (inside the devShell for stylua/shellcheck: nix develop -c scripts/smoke-test.sh)
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export NVIM_APPNAME=neopanda
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
trap 'rm -f "$result"' EXIT

# Collects startup errors and every ERROR line of the health report
"$NVIM" --headless -c "lua (function()
  local out = {}
  if vim.v.errmsg ~= '' then table.insert(out, 'startup: ' .. vim.v.errmsg) end
  vim.cmd('checkhealth neopanda vim.pack')
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    if line:find('ERROR') then table.insert(out, line) end
  end
  vim.fn.writefile(out, '$result')
  vim.cmd('qa!')
end)()" >/dev/null 2>&1 || fail "nvim exited with an error"

if [[ -s "$result" ]]; then
  fail "config / health:"
  sed 's/^/   /' "$result"
else
  pass "config loads, health has no ERROR"
fi

for script in "$REPO_DIR"/scripts/*.sh; do
  bash -n "$script" || fail "bash -n ${script#"$REPO_DIR"/}"
done
pass "bash -n scripts"

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
