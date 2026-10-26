#!/usr/bin/env bash
# Bootstrap neopanda on Ubuntu / WSL2 (no Nix). Safe to re-run.
# Run from a clone of this repo: scripts/bootstrap.sh [--dry-run]
set -euo pipefail

BOB_VERSION="v4.2.0"
declare -A BOB_SHA256=(
  [x86_64]="c5eb4341f10030eab6aa5ea7363afbee27d1c0835dba29447d3150ebab8f3f1a"
  [arm]="60f9739b3450c6d8c28067e7b88126442dde1d97c614c7c621109e0260b9bae3"
)
APT_PACKAGES=(git ripgrep fd-find build-essential curl unzip xclip)

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/neopanda"
BIN_DIR="$HOME/.local/bin"
BOB_BIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/bob/nvim-bin"
DRY_RUN=0

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

log() { printf '🐼 %s\n' "$*"; }
run() {
  if ((DRY_RUN)); then
    printf '   would run: %s\n' "$*"
  else
    "$@"
  fi
}

check_platform() {
  if ! command -v apt-get >/dev/null; then
    echo "apt-get not found: this script targets Ubuntu / WSL2" >&2
    exit 1
  fi
}

install_packages() {
  local missing=()
  for pkg in "${APT_PACKAGES[@]}"; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if ((${#missing[@]} == 0)); then
    log "apt packages already installed"
    return
  fi
  log "installing: ${missing[*]}"
  run sudo apt-get update
  run sudo apt-get install -y "${missing[@]}"
}

# Ubuntu ships fd as "fdfind"
link_fd() {
  if command -v fd >/dev/null || [[ -e "$BIN_DIR/fd" ]]; then
    log "fd already available"
    return
  fi
  log "linking fd -> fdfind"
  run mkdir -p "$BIN_DIR"
  run ln -sf "$(command -v fdfind || echo /usr/bin/fdfind)" "$BIN_DIR/fd"
}

install_bob() {
  if command -v bob >/dev/null || [[ -x "$BIN_DIR/bob" ]]; then
    log "bob already installed"
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm" ;;
    *)
      echo "unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
  local name="bob-linux-$arch"
  local tmp
  tmp="$(mktemp -d)"
  log "installing bob $BOB_VERSION ($arch)"
  run curl -fsSL -o "$tmp/$name.zip" "https://github.com/MordechaiHadad/bob/releases/download/$BOB_VERSION/$name.zip"
  if ((!DRY_RUN)); then
    echo "${BOB_SHA256[$arch]}  $tmp/$name.zip" | sha256sum --check --quiet
  fi
  run unzip -q "$tmp/$name.zip" -d "$tmp"
  run mkdir -p "$BIN_DIR"
  run install -m 755 "$tmp/$name/bob" "$BIN_DIR/bob"
  rm -rf "$tmp"
}

install_neovim() {
  log "installing Neovim nightly with bob"
  run env PATH="$BIN_DIR:$PATH" bob use nightly
}

# Moves an existing config (and its data) aside unless it already points to this repo
link_config() {
  if [[ "$(readlink -f "$CONFIG_DIR" 2>/dev/null)" == "$REPO_DIR" ]]; then
    log "config already linked to $REPO_DIR"
    return
  fi
  local stamp
  stamp="$(date +%Y%m%d-%H%M%S)"
  for dir in "$CONFIG_DIR" \
    "${XDG_DATA_HOME:-$HOME/.local/share}/neopanda" \
    "${XDG_STATE_HOME:-$HOME/.local/state}/neopanda" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/neopanda"; do
    if [[ -e "$dir" || -L "$dir" ]]; then
      log "backing up $dir -> $dir.bak.$stamp"
      run mv "$dir" "$dir.bak.$stamp"
    fi
  done
  log "linking $CONFIG_DIR -> $REPO_DIR"
  run mkdir -p "$(dirname "$CONFIG_DIR")"
  run ln -s "$REPO_DIR" "$CONFIG_DIR"
}

# PATH for bob/fd and the npd alias, once per rc file
setup_shell() {
  local marker="# neopanda"
  local block
  block=$(
    cat <<EOF
$marker
export PATH="$BIN_DIR:$BOB_BIN_DIR:\$PATH"
alias npd='NVIM_APPNAME=neopanda nvim'
EOF
  )
  for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
    [[ -f "$rc" ]] || continue
    if grep -qF "$marker" "$rc"; then
      log "$rc already set up"
    elif ((DRY_RUN)); then
      printf '   would append to %s:\n%s\n' "$rc" "$block"
    else
      log "adding PATH and npd alias to $rc"
      printf '\n%s\n' "$block" >>"$rc"
    fi
  done
}

main() {
  check_platform
  install_packages
  link_fd
  install_bob
  install_neovim
  link_config
  setup_shell
  log "done. Open a new shell and run: npd"
}

main
