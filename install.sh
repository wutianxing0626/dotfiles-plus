#!/usr/bin/env bash
# dotfiles-plus installer — 薄调度器，实际安装逻辑在每个功能的 install.sh 里。
#
# 用法:
#   ./install.sh                  # 安装全部功能
#   ./install.sh notify-done      # 只安装某个功能（可多个）
#
# 新增功能时：建 <功能名>/install.sh（幂等、自包含），并把它加进 FEATURES。
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEATURES=(codex_skill zsh notify-done)

targets=("$@")
[[ ${#targets[@]} -eq 0 ]] && targets=("${FEATURES[@]}")

for name in "${targets[@]}"; do
  inst="$REPO_DIR/$name/install.sh"
  if [[ ! -x "$inst" ]]; then
    echo "错误: 缺少可执行的 $name/install.sh" >&2
    exit 1
  fi
  echo "==> installing $name"
  "$inst"
done

echo "all done."
