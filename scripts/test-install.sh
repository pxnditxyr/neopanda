#!/usr/bin/env bash
# End-to-end install test: builds npd and runs it on empty XDG dirs, as a new user would. Needs network (45 clones).
# Usage: scripts/test-install.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NPD="$(nix build "$REPO_DIR" --no-link --print-out-paths 2>/dev/null)/bin/npd"
WORK="$(mktemp -d)"
trap 'chmod -R u+w "$WORK"; rm -rf "$WORK"' EXIT

failures=0
pass() { printf '✅ %s\n' "$*"; }
fail() {
  printf '❌ %s\n' "$*"
  failures=$((failures + 1))
}
check() { # check <description> <command...>
  local description="$1"
  shift
  if "$@"; then pass "$description"; else fail "$description"; fi
}

export XDG_CONFIG_HOME="$WORK/config" XDG_DATA_HOME="$WORK/data" XDG_STATE_HOME="$WORK/state" XDG_CACHE_HOME="$WORK/cache"
PLUGINS="$XDG_DATA_HOME/neopanda/site/pack/core/opt"
LOCK="$XDG_STATE_HOME/neopanda/nvim-pack-lock.json"
MARKER="$XDG_STATE_HOME/neopanda/nvim-pack-lock.seed"
PROJECT="$WORK/project"
mkdir -p "$PROJECT"

npd() { (cd "$PROJECT" && "$NPD" --headless "$@" +'qa!' >/dev/null 2>&1) || true; }
offline() { GIT_ALLOW_PROTOCOL=none npd; }

# Plugins whose installed rev differs from the lockfile's, or are missing. Empty file = in sync.
out_of_sync() { # out_of_sync <lockfile>
  local out="$WORK/out"
  npd -c "lua (function()
    local want = vim.json.decode(table.concat(vim.fn.readfile('$1'), '\n')).plugins
    local bad = {}
    for _, p in ipairs(vim.pack.get()) do
      if want[p.spec.name] and want[p.spec.name].rev ~= p.rev then table.insert(bad, p.spec.name) end
      want[p.spec.name] = nil
    end
    vim.list_extend(bad, vim.tbl_keys(want))
    vim.fn.writefile(bad, '$out')
  end)()"
  [[ ! -s "$out" ]]
}

health_clean() {
  local out="$WORK/health"
  npd -c "lua (function()
    vim.cmd('checkhealth neopanda vim.pack')
    local bad = vim.tbl_filter(function(l) return l:find('ERROR') end, vim.api.nvim_buf_get_lines(0, 0, -1, false))
    vim.fn.writefile(bad, '$out')
  end)()"
  [[ ! -s "$out" ]]
}

echo "🆕 first start"
PINNED="$(sed -n "s/^export NEOPANDA_CONFIG=.*'\(.*\)'}$/\1/p" "$NPD")/nvim-pack-lock.json"
npd
check "every plugin at its pinned rev" out_of_sync "$PINNED"
check "marker written" test -s "$MARKER"
check "state lockfile is writable" test -w "$LOCK"
check "nothing written to the config dir" test ! -e "$XDG_CONFIG_HOME/neopanda"
check "health has no ERROR" health_clean

echo "🔁 second start, no network"
before="$(cat "$MARKER")"
offline
check "marker unchanged" test "$(cat "$MARKER")" = "$before"
check "plugins still in sync" out_of_sync "$PINNED"

echo "❄️  new pinned lockfile"
CONFIG="$WORK/new-config"
cp -R "$(dirname "$PINNED")" "$CONFIG"
chmod -R u+w "$CONFIG"
plugin=mini.ai
old_rev="$(git -C "$PLUGINS/$plugin" rev-parse HEAD~1)"
new_rev="$(git -C "$PLUGINS/$plugin" rev-parse HEAD)"
sed -i.bak "s/$new_rev/$old_rev/" "$CONFIG/nvim-pack-lock.json"
rm "$CONFIG/nvim-pack-lock.json.bak"
chmod -R a-w "$CONFIG"
export NEOPANDA_CONFIG="$CONFIG"
npd
check "plugin moved to the new pin" test "$(git -C "$PLUGINS/$plugin" rev-parse HEAD)" = "$old_rev"
check "marker changed" test "$(cat "$MARKER")" != "$before"
check "state lockfile has the new pin" grep -q "$old_rev" "$LOCK"
unset NEOPANDA_CONFIG

echo "🔌 download fails, then retries"
npd # back to the pinned lockfile
rm -rf "${PLUGINS:?}/$plugin" "$MARKER"
offline
check "marker not written" test ! -e "$MARKER"
npd
check "plugin back at its pin" test -d "$PLUGINS/$plugin"
check "all in sync after the retry" out_of_sync "$PINNED"
check "marker written after the retry" test -s "$MARKER"

echo "🚫 very first start with no network"
export XDG_DATA_HOME="$WORK/data2" XDG_STATE_HOME="$WORK/state2"
offline
check "no marker" test ! -e "$XDG_STATE_HOME/neopanda/nvim-pack-lock.seed"

if ((failures)); then
  printf '\n%d check(s) failed\n' "$failures"
  exit 1
fi
printf '\n🐼 install works\n'
