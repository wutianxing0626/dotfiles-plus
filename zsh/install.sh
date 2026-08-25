#!/usr/bin/env bash
# install.sh — zsh 功能安装器（dotfiles-plus 模块化安装）
#
# 作用：把 ~/.zshrc 软链到仓库的 zsh/zshrc（通用配置），并保证机器相关配置
#       落在 ~/.zshrc.local（首次从 zsh/zshrc.local.example 生成）。
#       幂等：重复执行安全；~/.zshrc 若是真文件，先备份为 ~/.zshrc.pre-dotfiles。
#
# 用法：
#   ./install.sh
#   ./install.sh --help
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
用法: install.sh [--help]
安装内容:
  ~/.zshrc        ->  软链到本目录的 zsh/zshrc（通用 zsh 配置）
  ~/.zshrc.local  ->  首次从 zsh/zshrc.local.example 生成（机器相关，不进仓库）
  旧 ~/.zshrc     ->  若已是真文件，先备份为 ~/.zshrc.pre-dotfiles
EOF
}
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/zshrc"
EXAMPLE="$SCRIPT_DIR/zshrc.local.example"
TARGET="${ZDOTDIR:-$HOME}/.zshrc"
LOCAL="${ZDOTDIR:-$HOME}/.zshrc.local"
BACKUP="${ZDOTDIR:-$HOME}/.zshrc.pre-dotfiles"

[[ -f "$SRC" ]]     || { echo "错误: 缺少本目录的 zshrc" >&2; exit 1; }
[[ -f "$EXAMPLE" ]] || { echo "错误: 缺少本目录的 zshrc.local.example" >&2; exit 1; }

# 若 ~/.zshrc 是真文件（非我们已建的软链），先备份，避免覆盖已有内容
if [[ -e "$TARGET" && ! -L "$TARGET" ]]; then
  echo "备份现有 $TARGET -> $BACKUP"
  mv "$TARGET" "$BACKUP"
fi

# 软链 ~/.zshrc -> 仓库的 zsh/zshrc
ln -sfn "$SRC" "$TARGET"
echo "已软链 $TARGET -> $SRC"

# 机器相关配置：不存在才从示例生成（之后不再覆盖，避免覆盖用户手改内容）
if [[ ! -f "$LOCAL" ]]; then
  install -m 600 "$EXAMPLE" "$LOCAL"
  echo "已生成 $LOCAL（机器相关配置，请检查其中的 conda / nvm 路径）"
else
  echo "$LOCAL 已存在，跳过"
fi

# oh-my-zsh 自定义主题：把 bashmix 软链到 custom/themes，保证 ZSH_THEME="bashmix" 可用
THEME_SRC="$SCRIPT_DIR/themes/bashmix.zsh-theme"
THEMES_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes"
if [[ -f "$THEME_SRC" ]]; then
  mkdir -p "$THEMES_DIR"
  ln -sfn "$THEME_SRC" "$THEMES_DIR/bashmix.zsh-theme"
  echo "已软链 bashmix 主题 -> $THEMES_DIR/bashmix.zsh-theme"
else
  echo "提示: 未找到 $THEME_SRC，跳过主题链接（ZSH_THEME=bashmix 可能失效）"
fi

echo
echo "==> zsh 安装完成 ✅"
echo "  通用配置: $TARGET -> $SRC"
echo "  机器配置: $LOCAL"
echo "  主题: $THEMES_DIR/bashmix.zsh-theme"
echo "  注意: 若你之前的 conda/nvm 写在旧 ~/.zshrc，可在 $LOCAL 里补上（参考 $BACKUP）。"
echo "  生效: 新开终端，或 source ~/.zshrc"
