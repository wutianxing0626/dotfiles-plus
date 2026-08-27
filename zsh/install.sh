#!/usr/bin/env bash
# install.sh — zsh 功能安装器（dotfiles-plus 模块化安装）
#
# 作用：把 ~/.zshrc 做成“托管入口”（真文件），只负责 source 仓库的 zsh/zshrc；
#       机器相关配置落在 ~/.zshrc.local（首次从 zsh/zshrc.local.example 生成）。
#       不用软链的原因：conda init / nvm 等工具会往 ~/.zshrc 追加内容，
#       若 ~/.zshrc 是软链，这些内容会顺着写进仓库文件。改成真文件后，
#       机器写入只追加在入口后面，仓库文件保持干净（部分同步）。
#       幂等：重复执行安全；非本工具管理的真文件先备份为 ~/.zshrc.pre-dotfiles。
#
# 用法：
#   ./install.sh
#   ./install.sh --help
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
用法: install.sh [--help]
安装内容:
  ~/.zshrc        ->  生成“托管入口”（真文件），source 本目录的 zsh/zshrc；
                       conda init 等机器写入只追加在入口后面，不污染仓库
  ~/.zshrc.local  ->  首次从 zsh/zshrc.local.example 生成（机器相关，不进仓库）
  旧 ~/.zshrc     ->  非本工具管理的真文件先备份为 ~/.zshrc.pre-dotfiles
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

if [[ ! -d "${ZSH:-$HOME/.oh-my-zsh}" ]]; then
  echo "警告: 未找到 oh-my-zsh（${ZSH:-$HOME/.oh-my-zsh}）" >&2
  echo "  请先在仓库根目录执行 ./install.sh，它会自动安装 oh-my-zsh 和插件。" >&2
fi

# ---------- ~/.zshrc：生成/更新“托管入口”（真文件）----------
# 入口内容（托管段）只由本脚本维护；托管段之后的内容属于机器，原样保留。
managed_header() {
  cat <<EOF
# >>> dotfiles-plus: zshrc 托管入口（由 zsh/install.sh 维护）>>>
[ -f "$SRC" ] && source "$SRC"
# <<< dotfiles-plus: zshrc 托管入口 <<<

EOF
}

# 取出 conda init 写入的块（含标记行），用于迁移时保留；没有则输出为空
extract_conda_block() {
  awk '/^# >>> conda initialize >>>/{p=1} p{print} /^# <<< conda initialize <<</{p=0}'
}

if [[ ! -e "$TARGET" ]]; then
  managed_header > "$TARGET"
  echo "已生成 $TARGET（托管入口，source 仓库的 zsh/zshrc）"
elif [[ -L "$TARGET" ]]; then
  # 旧布局是软链：conda init 会顺着软链写进仓库文件。改成真文件，
  # 并把旧的 conda init 块挪到入口后面，避免机器上 conda 失效。
  old_content="$(cat "$TARGET" 2>/dev/null || true)"
  rm -f "$TARGET"
  managed_header > "$TARGET"
  if [[ -n "$old_content" ]] && printf '%s\n' "$old_content" | extract_conda_block | grep -q .; then
    printf '%s\n' "$old_content" | extract_conda_block >> "$TARGET"
    echo "已把旧的 conda init 块迁到 $TARGET（之后 conda 写入不再进仓库）"
  fi
  echo "已把 $TARGET 从软链改为托管入口（真文件）"
elif grep -q '^# >>> dotfiles-plus: zshrc' "$TARGET"; then
  # 已是托管入口：只更新托管段（比如仓库路径变了），托管段之后的机器内容原样保留
  tmp="${TARGET}.tmp"
  awk -v hdr="$(managed_header)" '
    /^# >>> dotfiles-plus: zshrc/ { in_block = 1; if (!done) { printf "%s", hdr; done = 1 } next }
    in_block && /^# <<< dotfiles-plus: zshrc/ { in_block = 0; next }
    !in_block { print }
  ' "$TARGET" > "$tmp"
  mv "$tmp" "$TARGET"
  echo "已更新 $TARGET 的托管入口（保留托管段之后的机器内容）"
else
  # 非本工具管理的真文件：先备份，再生成入口；旧的 conda init 块一并保留
  old_content="$(cat "$TARGET")"
  echo "备份现有 $TARGET -> $BACKUP"
  mv "$TARGET" "$BACKUP"
  managed_header > "$TARGET"
  if [[ -n "$old_content" ]] && printf '%s\n' "$old_content" | extract_conda_block | grep -q .; then
    printf '%s\n' "$old_content" | extract_conda_block >> "$TARGET"
    echo "已保留原文件里的 conda init 块（其余机器内容见 $BACKUP）"
  fi
  echo "已生成 $TARGET（托管入口）；机器专属内容请从 $BACKUP 移到 $LOCAL"
fi
chmod 644 "$TARGET"

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
echo "  托管入口: $TARGET（source: $SRC）"
echo "  机器配置: $LOCAL"
echo "  主题: $THEMES_DIR/bashmix.zsh-theme"
echo "  说明: conda init / nvm 等机器写入会追加在 $TARGET 的托管段之后，不会进仓库。"
echo "  生效: 新开终端，或 source ~/.zshrc"
