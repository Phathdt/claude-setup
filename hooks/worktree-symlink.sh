#!/bin/bash
# worktree-symlink.sh — Hook for WorktreeCreate event
# Reads worktree.yml from ~/ (global) and repo root (project), creates symlinks

INPUT=$(cat)
WORKTREE_PATH=$(echo "$INPUT" | jq -r '.worktree_path // empty')
PROJECT_DIR=$(echo "$INPUT" | jq -r '.cwd // empty')

if [[ -z "$WORKTREE_PATH" || -z "$PROJECT_DIR" ]]; then
  echo "Error: missing worktree_path or cwd from hook input" >&2
  exit 1
fi

# Resolve real repo root (in case cwd is already a worktree)
REPO_ROOT=$(cd "$PROJECT_DIR" && git rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname)
GLOBAL_CONFIG="$HOME/.worktree.yml"
PROJECT_CONFIG="$REPO_ROOT/worktree.yml"

# Parse yaml file, output one path per line
parse_yaml() {
  local file="$1"
  [[ ! -f "$file" ]] && return
  while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -z "$line" || "$line" =~ ^# || "$line" =~ ^[a-zA-Z_-]+:$ ]] && continue
    line=$(echo "$line" | sed 's/^-[[:space:]]*//')
    line="${line%/}"
    echo "$line"
  done < "$file"
}

# Merge global + project configs, deduplicate
{ parse_yaml "$GLOBAL_CONFIG"; parse_yaml "$PROJECT_CONFIG"; } | sort -u | while IFS= read -r path; do
  source_path="$REPO_ROOT/$path"
  target_path="$WORKTREE_PATH/$path"

  # Silently skip if source doesn't exist
  [[ ! -e "$source_path" ]] && continue

  rm -rf "$target_path"
  mkdir -p "$(dirname "$target_path")"
  ln -sf "$source_path" "$target_path"
  echo "  Linked: $path" >&2
done

echo "$WORKTREE_PATH"
exit 0
