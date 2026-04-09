#!/bin/bash
# worktree-symlink.sh — Hook for WorktreeCreate event
# Reads worktree.yaml from repo root and creates symlinks in the new worktree

INPUT=$(cat)
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // empty')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$WORKTREE_PATH" || -z "$PROJECT_DIR" ]]; then
  echo "Error: missing worktree_path or cwd from hook input" >&2
  exit 1
fi

# Resolve real repo root (in case cwd is already a worktree)
REPO_ROOT=$(cd "$PROJECT_DIR" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname)
CONFIG_FILE="$REPO_ROOT/worktree.yaml"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "No worktree.yaml found, skipping symlinks" >&2
  echo "$WORKTREE_PATH"
  exit 0
fi

# Parse worktree.yaml and create symlinks
while IFS= read -r line; do
  line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [[ -z "$line" || "$line" =~ ^# || "$line" =~ ^[a-zA-Z_-]+:$ ]] && continue
  line=$(echo "$line" | sed 's/^-[[:space:]]*//')
  line="${line%/}"

  source_path="$REPO_ROOT/$line"
  target_path="$WORKTREE_PATH/$line"

  if [[ ! -e "$source_path" ]]; then
    echo "  Skip: $line (not found in repo root)" >&2
    continue
  fi

  rm -rf "$target_path"
  mkdir -p "$(dirname "$target_path")"
  ln -sf "$source_path" "$target_path"
  echo "  Linked: $line" >&2
done < "$CONFIG_FILE"

echo "$WORKTREE_PATH"
exit 0
