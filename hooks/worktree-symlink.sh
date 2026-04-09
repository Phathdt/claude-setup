#!/bin/bash
# worktree-symlink.sh — Hook for WorktreeCreate event
# Reads worktree.yml from ~/ (global) and repo root (project)
# Creates symlinks and runs scripts

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

# Parse a section from yaml file
parse_section() {
  local file="$1" section="$2"
  [[ ! -f "$file" ]] && return
  local in_section=false
  while IFS= read -r line; do
    local trimmed
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -z "$trimmed" || "$trimmed" =~ ^# ]] && continue
    if [[ "$trimmed" =~ ^[a-zA-Z_-]+:$ ]]; then
      [[ "$trimmed" == "${section}:" ]] && in_section=true || in_section=false
      continue
    fi
    if $in_section; then
      trimmed=$(echo "$trimmed" | sed 's/^-[[:space:]]*//')
      echo "$trimmed"
    fi
  done < "$file"
}

# Symlinks: merge global + project, deduplicate
{ parse_section "$GLOBAL_CONFIG" "symlinks"; parse_section "$PROJECT_CONFIG" "symlinks"; } | sort -u | while IFS= read -r path; do
  source_path="$REPO_ROOT/$path"
  target_path="$WORKTREE_PATH/$path"

  [[ ! -e "$source_path" ]] && continue

  rm -rf "$target_path"
  mkdir -p "$(dirname "$target_path")"
  ln -sf "$source_path" "$target_path"
  echo "  Linked: $path" >&2
done

# Copies: APFS clone (instant, zero disk)
{ parse_section "$GLOBAL_CONFIG" "copies"; parse_section "$PROJECT_CONFIG" "copies"; } | sort -u | while IFS= read -r path; do
  source_path="$REPO_ROOT/$path"
  target_path="$WORKTREE_PATH/$path"

  [[ ! -e "$source_path" ]] && continue

  rm -rf "$target_path"
  mkdir -p "$(dirname "$target_path")"
  cp -c -R "$source_path" "$target_path" 2>/dev/null \
    || cp -R --reflink=auto "$source_path" "$target_path" 2>/dev/null \
    || cp -R "$source_path" "$target_path"
  echo "  Copied: $path" >&2
done

# Scripts: global first, then project (order matters)
{
  parse_section "$GLOBAL_CONFIG" "scripts"
  parse_section "$PROJECT_CONFIG" "scripts"
} | while IFS= read -r cmd; do
  [[ -z "$cmd" ]] && continue
  echo "  Run: $cmd" >&2
  (cd "$WORKTREE_PATH" && eval "$cmd") >&2 2>&1 || echo "  Warning: script failed: $cmd" >&2
done

echo "$WORKTREE_PATH"
exit 0
