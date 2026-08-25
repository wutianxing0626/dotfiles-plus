#!/usr/bin/env bash
# install.sh — tmux 功能安装器（dotfiles-plus 模块化安装）
#
# 作用：把 ~/.tmux.conf 和 ~/.tmux.conf.local 软链到仓库的 tmux/ 下。
#       幂等：重复执行安全；若目标是真文件，先备份为 *.pre-dotfiles；
#       若已是软链（例如指向 ~/terminal），会被重新指向仓库。
#
# 用法：
#   ./install.sh
#   ./install.sh --help
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
用法: install.sh [--help]
安装内容:
  ~/.tmux.conf        ->  软链到本目录的 tmux/.tmux.conf
  ~/.tmux.conf.local  ->  软链到本目录的 tmux/.tmux.conf.local
  旧真文件            ->  若存在，先备份为 .tmux.conf[.local].pre-dotfiles
EOF
}
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_SRC="$SCRIPT_DIR/.tmux.conf"
LOCAL_SRC="$SCRIPT_DIR/.tmux.conf.local"
CONF_TARGET="$HOME/.tmux.conf"
LOCAL_TARGET="$HOME/.tmux.conf.local"

[[ -f "$CONF_SRC" ]]  || { echo "错误: 缺少本目录的 .tmux.conf" >&2; exit 1; }
[[ -f "$LOCAL_SRC" ]] || { echo "错误: 缺少本目录的 .tmux.conf.local" >&2; exit 1; }

# 备份真文件（软链不备份：原内容仍保留在别处）
link_or_backup() {
  local src="$1" target="$2"
  if [[ -e "$target" && ! -L "$target" ]]; then
    echo "备份现有 $target -> $target.pre-dotfiles"
    mv "$target" "$target.pre-dotfiles"
  fi
  ln -sfn "$src" "$target"
  echo "已软链 $target -> $src"
}

link_or_backup "$CONF_SRC" "$CONF_TARGET"
link_or_backup "$LOCAL_SRC" "$LOCAL_TARGET"

echo
echo "==> tmux 安装完成 ✅"
echo "  $CONF_TARGET   -> $CONF_SRC"
echo "  $LOCAL_TARGET  -> $LOCAL_SRC"
echo "  生效: 重开 tmux，或在 tmux 内执行  tmux source-file ~/.tmux.conf"
