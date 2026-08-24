#!/usr/bin/env bash
# install.sh — codex_skill 功能安装器：把仓库内每个 skill 软链到 $CODEX_HOME/skills/
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

mkdir -p "$CODEX_SKILLS_DIR"
for skill in "$REPO_DIR"/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  ln -sfn "$skill" "$CODEX_SKILLS_DIR/$name"
  echo "linked codex skill: $name"
done
