#!/usr/bin/env bash
# dotfiles-plus installer: link repo contents into their canonical locations.
# Idempotent; safe to re-run.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_SKILLS_DIR="${CODEX_HOME:-$HOME/.codex}/skills"

# Codex skills: one subdirectory per skill.
mkdir -p "$CODEX_SKILLS_DIR"
for skill in "$REPO_DIR"/codex_skill/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  ln -sfn "$skill" "$CODEX_SKILLS_DIR/$name"
  echo "linked codex skill: $name"
done

echo "done."
