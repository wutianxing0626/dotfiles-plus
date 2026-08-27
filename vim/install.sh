#!/usr/bin/env bash
# install.sh — vim 功能安装器（dotfiles-plus 模块化安装）
#
# 作用：把 ~/.vimrc 软链到仓库的 vim/.vimrc。
#       幂等：重复执行安全；若目标是真文件，先备份为 .vimrc.pre-dotfiles；
#       若已是软链（例如指向 ~/vim_learning/vimrc），会被重新指向仓库。
#
# 用法：
#   ./install.sh
#   ./install.sh --help
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
用法: install.sh [--help]
安装内容:
  ~/.vimrc  ->  软链到本目录的 vim/.vimrc
  旧真文件  ->  若存在，先备份为 .vimrc.pre-dotfiles
EOF
}
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.vimrc"
TARGET="$HOME/.vimrc"

[[ -f "$SRC" ]] || { echo "错误: 缺少本目录的 .vimrc" >&2; exit 1; }

# 备份真文件（软链不备份：原内容仍保留在别处）
if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  echo "备份现有 $TARGET -> $TARGET.pre-dotfiles"
  mv "$TARGET" "$TARGET.pre-dotfiles"
fi
ln -sfn "$SRC" "$TARGET"
echo "已软链 $TARGET -> $SRC"

echo
echo "==> vim 安装完成 ✅"
echo "  $TARGET   -> $SRC"
echo "  生效: 新开 vim，或在 vim 里执行  :source ~/.vimrc"
