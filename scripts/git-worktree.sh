#!/bin/bash
set -euo pipefail

# git-worktree.sh — Create/remove git worktrees with automatic symlinks from worktree.yml
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
GLOBAL_CONFIG="$HOME/.worktree.yml"
CONFIG_FILE="$REPO_ROOT/worktree.yml"
WORKTREE_BASE="${GW_WORKTREE_BASE:-$REPO_ROOT/worktrees}"

# Sanitize branch name for directory: feature/abc → feature-abc
sanitize_dir() {
  echo "$1" | sed 's|/|-|g'
}

usage() {
  cat <<EOF
Usage: gw <command> <branch> [options]

Commands:
  add <branch>       Create worktree, symlink, and cd into it
  cd <branch>        cd to existing worktree
  root               cd back to repo root
  remove <branch>    Remove worktree (add -D to also delete branch)
  remove --all       Remove all worktrees (add -D to also delete branches)
  ls                 List all worktrees

Options:
  -c, --create       Create branch if it doesn't exist (used with 'add')
  -b <base>          Base branch for new branch (default: current branch)

Config (worktree.yml):
  Global: ~/.worktree.yml (shared across all repos)
  Project: <repo-root>/worktree.yml (project-specific)
  Both are merged; missing sources are silently skipped.

  symlinks:
    - .env
  copies:
    - node_modules       # APFS clone, instant
  scripts:
    - yarn prepare
EOF
  exit 1
}

_parse_section() {
  local file="$1" section="$2"
  [[ ! -f "$file" ]] && return
  local in_section=false
  while IFS= read -r line; do
    local trimmed
    trimmed=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -z "$trimmed" || "$trimmed" =~ ^# ]] && continue
    # Section header (e.g., "symlinks:" or "scripts:")
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

parse_symlinks() {
  { _parse_section "$GLOBAL_CONFIG" "symlinks"; _parse_section "$CONFIG_FILE" "symlinks"; } | sort -u
}

parse_copies() {
  { _parse_section "$GLOBAL_CONFIG" "copies"; _parse_section "$CONFIG_FILE" "copies"; } | sort -u
}

parse_scripts() {
  # Global first, then project — order matters, no dedup
  _parse_section "$GLOBAL_CONFIG" "scripts"
  _parse_section "$CONFIG_FILE" "scripts"
}

create_symlinks() {
  local worktree_dir="$1"

  parse_symlinks | while IFS= read -r path; do
    local source="$REPO_ROOT/$path"
    local target="$worktree_dir/$path"

    # Silently skip if source doesn't exist (global config may define paths not in this project)
    [[ ! -e "$source" ]] && continue

    rm -rf "$target"
    mkdir -p "$(dirname "$target")"
    ln -sf "$source" "$target"
    echo "  Linked: $path" >&2
  done
}

create_copies() {
  local worktree_dir="$1"

  parse_copies | while IFS= read -r path; do
    local source="$REPO_ROOT/$path"
    local target="$worktree_dir/$path"

    [[ ! -e "$source" ]] && continue

    rm -rf "$target"
    mkdir -p "$(dirname "$target")"
    # CoW copy: macOS (cp -c) or Linux btrfs/xfs (cp --reflink=auto), fallback to regular copy
    cp -c -R "$source" "$target" 2>/dev/null \
      || cp -R --reflink=auto "$source" "$target" 2>/dev/null \
      || cp -R "$source" "$target"
    echo "  Copied: $path" >&2
  done
}

run_scripts() {
  local worktree_dir="$1"

  parse_scripts | while IFS= read -r cmd; do
    [[ -z "$cmd" ]] && continue
    echo "  Run: $cmd" >&2
    (cd "$worktree_dir" && eval "$cmd") >&2 2>&1 || echo "  Warning: script failed: $cmd" >&2
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

  local dir_name
  dir_name=$(sanitize_dir "$branch")
  local worktree_dir="$WORKTREE_BASE/$dir_name"

  if [[ -d "$worktree_dir" ]]; then
    echo "Error: worktree already exists at $worktree_dir" >&2
    exit 1
  fi

  echo "Creating worktree for branch: $branch → $dir_name" >&2

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

  echo "Copying files..." >&2
  create_copies "$worktree_dir"

  echo "Running scripts..." >&2
  run_scripts "$worktree_dir"

  echo "" >&2
  echo "Worktree ready: $worktree_dir" >&2

  # Output path to stdout (for gw function to cd into)
  echo "$worktree_dir"
}

cmd_cd() {
  local branch="${1:-}"
  [[ -z "$branch" ]] && { echo "Error: branch name required"; usage; }

  local dir_name
  dir_name=$(sanitize_dir "$branch")
  local worktree_dir="$WORKTREE_BASE/$dir_name"

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
  local branch=""
  local delete_branch=false
  local remove_all=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -D) delete_branch=true; shift ;;
      --all) remove_all=true; shift ;;
      -*) echo "Unknown option: $1"; usage ;;
      *) branch="$1"; shift ;;
    esac
  done

  if $remove_all; then
    _remove_all_worktrees "$delete_branch"
    echo "$REPO_ROOT"
    return
  fi

  [[ -z "$branch" ]] && { echo "Error: branch name required"; usage; }

  local dir_name
  dir_name=$(sanitize_dir "$branch")
  local worktree_dir="$WORKTREE_BASE/$dir_name"

  if [[ ! -d "$worktree_dir" ]]; then
    echo "Error: worktree not found at $worktree_dir" >&2
    exit 1
  fi

  echo "Removing worktree: $branch" >&2
  git worktree remove "$worktree_dir" --force

  if $delete_branch; then
    echo "Deleting branch: $branch" >&2
    git branch -D "$branch" 2>/dev/null || echo "  Warning: branch $branch not found or is current" >&2
  fi

  echo "Done" >&2

  echo "$REPO_ROOT"
}

_remove_all_worktrees() {
  local delete_branch="$1"
  local count=0

  # List worktrees excluding the main one (first entry is always the main worktree)
  while IFS= read -r line; do
    local wt_path wt_branch
    wt_path=$(echo "$line" | awk '{print $1}')
    wt_branch=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')

    # Skip the main worktree
    [[ "$wt_path" == "$REPO_ROOT" ]] && continue

    echo "Removing worktree: $wt_branch ($wt_path)" >&2
    git worktree remove "$wt_path" --force 2>/dev/null || {
      echo "  Warning: failed to remove $wt_path, trying cleanup" >&2
      rm -rf "$wt_path"
      git worktree prune
    }

    if [[ "$delete_branch" == "true" ]] && [[ -n "$wt_branch" ]]; then
      echo "Deleting branch: $wt_branch" >&2
      git branch -D "$wt_branch" 2>/dev/null || true
    fi

    ((count++))
  done < <(git worktree list)

  if [[ $count -eq 0 ]]; then
    echo "No worktrees to remove" >&2
  else
    echo "Removed $count worktree(s)" >&2
  fi
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
  remove) cmd_remove "$@" ;;
  ls|list) cmd_list ;;
  *)       echo "Unknown command: $command"; usage ;;
esac
