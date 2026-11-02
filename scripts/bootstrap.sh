#!/usr/bin/env bash
# Bootstrap neopanda on Ubuntu / WSL2 (no Nix). Safe to re-run.
# Run from a clone of this repo: scripts/bootstrap.sh [--dry-run]
set -euo pipefail

BOB_VERSION="v4.2.0"
declare -A BOB_SHA256=(
  [x86_64]="c5eb4341f10030eab6aa5ea7363afbee27d1c0835dba29447d3150ebab8f3f1a"
  [arm]="60f9739b3450c6d8c28067e7b88126442dde1d97c614c7c621109e0260b9bae3"
)
# nvim-treesitter needs tree-sitter-cli 0.26.1+; apt's is older
TS_VERSION="v0.27.1"
declare -A TS_SHA256=(
  [x64]="c7e686aec16ba17053c2e6fd87600ccb10cf8ba3d055756b17e756d538e11114"
  [arm64]="3c0d0113cae3fea36f2336c271cbdacbcdb349edb006319155652b9386803c55"
)
HURL_VERSION="8.0.1"
declare -A HURL_SHA256=(
  [x86_64]="cac7c4670d69444db120edb21fe06c97ba8c80dcc52279957c8dd18f05fb0c06"
  [aarch64]="bc4732df4754748e9bf296aa3832ec019f798afb399f1279b72ed37b6e04525c"
)
LAZYGIT_VERSION="0.66.2"
declare -A LAZYGIT_SHA256=(
  [x86_64]="158efc9ddfa1241fab5fb3526bb442c8dc6c4b1904d73213b9e4e93e03c52034"
  [arm64]="79a3161eeb642f0473e23db6341f7baabd4a5933e921a9c1167c5d5c765c41a4"
)
# Mason installs some LSP servers through npm; apt's nodejs (18) is too old for them
NODE_MIN_MAJOR=22
NODE_VERSION="v26.12.1"
declare -A NODE_SHA256=(
  [x64]="6170b2d474e1c626f43cff3adc118df9fe3b573258a4fc3d850c8dbc6b079bbd"
  [arm64]="42aa04922591ee5d4dbc7740d452621acf28508239daa512f5ee8c47ee224fdb"
)
# python3-venv: Mason installs some LSP servers through pip; libxml2: hurl; jq: hurl.nvim JSON formatting;
# psql/sqlite3/mysql: dadbod
APT_PACKAGES=(git ripgrep fd-find build-essential curl unzip xz-utils xclip inotify-tools python3-venv
  libxml2 jq postgresql-client sqlite3 mariadb-client)

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

install_tree_sitter() {
  if [[ -x "$BIN_DIR/tree-sitter" ]]; then
    log "tree-sitter already installed"
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      echo "unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
  local name="tree-sitter-cli-linux-$arch"
  local tmp
  tmp="$(mktemp -d)"
  log "installing tree-sitter $TS_VERSION ($arch)"
  run curl -fsSL -o "$tmp/$name.zip" "https://github.com/tree-sitter/tree-sitter/releases/download/$TS_VERSION/$name.zip"
  if ((!DRY_RUN)); then
    echo "${TS_SHA256[$arch]}  $tmp/$name.zip" | sha256sum --check --quiet
  fi
  run unzip -q "$tmp/$name.zip" -d "$tmp"
  run mkdir -p "$BIN_DIR"
  run install -m 755 "$tmp/tree-sitter" "$BIN_DIR/tree-sitter"
  rm -rf "$tmp"
}

install_lazygit() {
  if [[ -x "$BIN_DIR/lazygit" ]]; then
    log "lazygit already installed"
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      echo "unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
  local name="lazygit_${LAZYGIT_VERSION}_linux_$arch"
  local tmp
  tmp="$(mktemp -d)"
  log "installing lazygit $LAZYGIT_VERSION ($arch)"
  run curl -fsSL -o "$tmp/$name.tar.gz" "https://github.com/jesseduffield/lazygit/releases/download/v$LAZYGIT_VERSION/$name.tar.gz"
  if ((!DRY_RUN)); then
    echo "${LAZYGIT_SHA256[$arch]}  $tmp/$name.tar.gz" | sha256sum --check --quiet
  fi
  run tar -xzf "$tmp/$name.tar.gz" -C "$tmp" lazygit
  run mkdir -p "$BIN_DIR"
  run install -m 755 "$tmp/lazygit" "$BIN_DIR/lazygit"
  rm -rf "$tmp"
}

# Not in apt (24.04) nor Mason; links libcurl (curl) and libxml2 from apt
install_hurl() {
  if [[ -x "$BIN_DIR/hurl" ]]; then
    log "hurl already installed"
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64) arch="x86_64" ;;
    aarch64 | arm64) arch="aarch64" ;;
    *)
      echo "unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
  local name="hurl-${HURL_VERSION}-${arch}-unknown-linux-gnu"
  local tmp
  tmp="$(mktemp -d)"
  log "installing hurl $HURL_VERSION ($arch)"
  run curl -fsSL -o "$tmp/$name.tar.gz" "https://github.com/Orange-OpenSource/hurl/releases/download/$HURL_VERSION/$name.tar.gz"
  if ((!DRY_RUN)); then
    echo "${HURL_SHA256[$arch]}  $tmp/$name.tar.gz" | sha256sum --check --quiet
  fi
  run tar -xzf "$tmp/$name.tar.gz" -C "$tmp" "$name/bin/hurl"
  run mkdir -p "$BIN_DIR"
  run install -m 755 "$tmp/$name/bin/hurl" "$BIN_DIR/hurl"
  rm -rf "$tmp"
}

# Official installer (it verifies the binary's checksum itself); keeps its own auto-update
install_claude() {
  if PATH="$BIN_DIR:$PATH" command -v claude >/dev/null; then
    log "claude already installed"
    return
  fi
  log "installing Claude Code"
  run bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
}

# Keeps any Node >= NODE_MIN_MAJOR already installed; otherwise installs NODE_VERSION into ~/.local
install_node() {
  local node
  node="$(PATH="$BIN_DIR:$PATH" command -v node || true)"
  if [[ -n "$node" ]] && (($("$node" -p 'process.versions.node.split(".")[0]') >= NODE_MIN_MAJOR)); then
    log "node $("$node" --version) already installed"
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64) arch="x64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      echo "unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
  local name="node-$NODE_VERSION-linux-$arch.tar.xz"
  local tmp
  tmp="$(mktemp -d)"
  log "installing Node $NODE_VERSION ($arch) into $HOME/.local"
  run curl -fsSL -o "$tmp/$name" "https://nodejs.org/dist/$NODE_VERSION/$name"
  if ((!DRY_RUN)); then
    echo "${NODE_SHA256[$arch]}  $tmp/$name" | sha256sum --check --quiet
  fi
  run mkdir -p "$HOME/.local"
  run tar -xJf "$tmp/$name" -C "$HOME/.local" --strip-components=1 --exclude='*/README.md' --exclude='*/LICENSE' --exclude='*/CHANGELOG.md'
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
  install_tree_sitter
  install_lazygit
  install_hurl
  install_claude
  install_node
  install_neovim
  link_config
  setup_shell
  log "done. Open a new shell and run: npd"
}

main
