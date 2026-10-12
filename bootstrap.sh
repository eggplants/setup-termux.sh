#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

repo='https://github.com/eggplants/setup-termux.sh.git'
config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/mise"

if ! command -v mise &>/dev/null || ! command -v git &>/dev/null; then
  pkg upgrade -y
  pkg install -y mise git
fi

if [[ ! -d "$config_dir/.git" ]]; then
  git clone "$repo" "$config_dir"
fi

# [bootstrap.plugins] only takes Git URLs, so link the bundled pkg plugin
mise plugins link --force pkg "$config_dir/plugins/pkg"

mise bootstrap "$@"
