#!/usr/bin/env bash
# dotfiles-plus installer — 先装 zsh 前置依赖（oh-my-zsh + 插件），再调度各功能。
# 实际安装逻辑在每个功能的 install.sh 里。
#
# 用法:
#   ./install.sh                  # 安装全部功能
#   ./install.sh notify-done      # 只安装某个功能（可多个）
#
# 新增功能时：建 <功能名>/install.sh（幂等、自包含），并把它加进 FEATURES。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES=(codex_skill zsh notify-done tmux vim)

# ---------- 第一步：oh-my-zsh 与 zsh 插件（幂等，已装则跳过）----------
ensure_zsh_prereqs() {
  local omz="${ZSH:-$HOME/.oh-my-zsh}"
  local custom="${ZSH_CUSTOM:-$omz/custom}"

  command -v git >/dev/null 2>&1 || {
    echo "错误: 需要 git 命令，请先安装（Debian/Ubuntu: sudo apt-get install -y git）" >&2
    exit 1
  }

  if [[ -d "$omz" ]]; then
    echo "oh-my-zsh 已存在: $omz（跳过）"
  else
    echo "安装 oh-my-zsh -> $omz"
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$omz"
  fi

  mkdir -p "$custom/plugins"
  local name
  for name in zsh-autosuggestions zsh-syntax-highlighting; do
    if [[ -d "$custom/plugins/$name" ]]; then
      echo "zsh 插件已存在: $name（跳过）"
    else
      echo "安装 zsh 插件: $name"
      git clone --depth=1 "https://github.com/zsh-users/$name.git" "$custom/plugins/$name"
    fi
  done
}

targets=("$@")
[[ ${#targets[@]} -eq 0 ]] && targets=("${FEATURES[@]}")

# 只要目标里有 zsh，就先保证 oh-my-zsh 和插件就位
if [[ " ${targets[*]} " == *" zsh "* ]]; then
  echo "==> 检查 zsh 前置依赖（oh-my-zsh + 插件）"
  ensure_zsh_prereqs
fi

for name in "${targets[@]}"; do
  inst="$REPO_DIR/$name/install.sh"
  if [[ ! -x "$inst" ]]; then
    echo "错误: 缺少可执行的 $name/install.sh" >&2
    exit 1
  fi
  echo "==> installing $name"
  "$inst"
done

if [[ " ${targets[*]} " == *" zsh "* && "$(basename "${SHELL:-}")" != "zsh" ]]; then
  echo "提醒: 当前默认 shell 不是 zsh，可执行  chsh -s \"\$(command -v zsh)\"  后重新登录生效。"
fi

echo "all done."
