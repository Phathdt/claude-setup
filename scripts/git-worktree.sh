#!/bin/bash
set -euo pipefail

# git-worktree.sh — Create/remove git worktrees with automatic symlinks from worktree.yaml
#
# Usage: source the gw() function from your .zshrc/.bashrc, then use:
#   gw add <branch>       — create worktree + cd into it
#   gw cd <branch>        — cd to existing worktree
#   gw root               — cd back to repo root
#   gw remove <branch>    — remove worktree (cd to root first)
#   gw list               — list all worktrees
#
# Or run directly: ./scripts/git-worktree.sh <command> [args]
#   (direct run cannot cd — prints path instead)

# Resolve the real repo root (not the worktree root)
_git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || { echo "Error: not a git repository"; exit 1; }
REPO_ROOT=$(dirname "$_git_common_dir")
CONFIG_FILE="$REPO_ROOT/worktree.yaml"
WORKTREE_BASE="${GW_WORKTREE_BASE:-$REPO_ROOT/.claude/worktrees}"

usage() {
  cat <<EOF
Usage: gw <command> <branch> [options]

Commands:
  add <branch>       Create worktree, symlink, and cd into it
  cd <branch>        cd to existing worktree
  root               cd back to repo root
  remove <branch>    Remove worktree and clean up
  ls                 List all worktrees

Options:
  -c, --create       Create branch if it doesn't exist (used with 'add')
  -b <base>          Base branch for new branch (default: current branch)

Config (worktree.yaml at repo root):
  symlinks:
    - .env
    - node_modules
    - fun/node_modules
    - .turbo
EOF
  exit 1
}

parse_config() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Warning: $CONFIG_FILE not found, skipping symlinks" >&2
    return
  fi

  while IFS= read -r line; do
    line=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -z "$line" || "$line" =~ ^# || "$line" =~ ^[a-zA-Z_-]+:$ ]] && continue
    line=$(echo "$line" | sed 's/^-[[:space:]]*//')
    line="${line%/}"
    echo "$line"
  done < "$CONFIG_FILE"
}

create_symlinks() {
  local worktree_dir="$1"

  parse_config | while IFS= read -r path; do
    local source="$REPO_ROOT/$path"
    local target="$worktree_dir/$path"

    if [[ ! -e "$source" ]]; then
      echo "  Skip: $path (not found in repo root)" >&2
      continue
    fi

    rm -rf "$target"
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    echo "  Linked: $path" >&2
  done
}

cmd_add() {
  local branch=""
  local create_branch=false
  local base_branch=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -c|--create) create_branch=true; shift ;;
      -b) base_branch="$2"; shift 2 ;;
      -*) echo "Unknown option: $1"; usage ;;
      *) branch="$1"; shift ;;
    esac
  done

  [[ -z "$branch" ]] && { echo "Error: branch name required"; usage; }

  local worktree_dir="$WORKTREE_BASE/$branch"

  if [[ -d "$worktree_dir" ]]; then
    echo "Error: worktree already exists at $worktree_dir" >&2
    exit 1
  fi

  echo "Creating worktree for branch: $branch" >&2

  # Auto-detect: create branch if it doesn't exist
  if ! $create_branch && ! git rev-parse --verify "$branch" &>/dev/null; then
    create_branch=true
  fi

  if $create_branch; then
    local base="${base_branch:-HEAD}"
    git worktree add -b "$branch" "$worktree_dir" "$base" >&2
  else
    git worktree add "$worktree_dir" "$branch" >&2
  fi

  echo "Creating symlinks..." >&2
  create_symlinks "$worktree_dir"

  echo "" >&2
  echo "Worktree ready: $worktree_dir" >&2

  # Output path to stdout (for gw function to cd into)
  echo "$worktree_dir"
}

cmd_cd() {
  local branch="${1:-}"
  [[ -z "$branch" ]] && { echo "Error: branch name required"; usage; }

  local worktree_dir="$WORKTREE_BASE/$branch"

  if [[ ! -d "$worktree_dir" ]]; then
    echo "Error: worktree not found at $worktree_dir" >&2
    exit 1
  fi

  echo "$worktree_dir"
}

cmd_root() {
  echo "$REPO_ROOT"
}

cmd_remove() {
  local branch="${1:-}"
  [[ -z "$branch" ]] && { echo "Error: branch name required"; usage; }

  local worktree_dir="$WORKTREE_BASE/$branch"

  if [[ ! -d "$worktree_dir" ]]; then
    echo "Error: worktree not found at $worktree_dir" >&2
    exit 1
  fi

  echo "Removing worktree: $branch" >&2
  git worktree remove "$worktree_dir" --force
  echo "Done" >&2

  echo "$REPO_ROOT"
}

cmd_list() {
  git worktree list
}

# --- main ---

[[ $# -lt 1 ]] && usage

command="$1"
shift

case "$command" in
  add)    cmd_add "$@" ;;
  cd)     cmd_cd "${1:-}" ;;
  root)   cmd_root ;;
  remove) cmd_remove "${1:-}" ;;
  ls|list) cmd_list ;;
  *)       echo "Unknown command: $command"; usage ;;
esac
