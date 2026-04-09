# Git Worktree Workflow

Manage multiple working directories from a single repo using `git worktree` with automatic symlinks for shared resources (node_modules, .env, .turbo, etc.).

## Scripts

- `scripts/git-worktree.sh` — Core logic (create, remove, list, symlink)
- `scripts/git-worktree-wrapper.sh` — Shell wrapper function `gw()` for `cd` support
- `hooks/worktree-symlink.sh` — WorktreeCreate hook for Claude Code's built-in worktrees

## Setup

Handled automatically by `install.sh` (adds source line to `.zshrc`/`.bashrc`).

Manual setup if needed:

```bash
source /path/to/scripts/git-worktree-wrapper.sh
```

## Config: `worktree.yml`

Two levels, merged together with deduplication:

- **Global**: `~/.worktree.yml` — shared across all repos
- **Project**: `<repo-root>/worktree.yml` — project-specific

Missing sources are silently skipped (global config may define paths not in every project).

```yaml
symlinks:
  - .env
  - node_modules
  - fun/node_modules
  - .turbo
```

## Commands

### `gw add <branch> [-b <base>]`

Create worktree at `worktrees/<branch>` + auto cd into it. Auto-creates branch if it doesn't exist.

```bash
# Auto-creates branch if not exists, based on HEAD
gw add feature/auth

# Create from specific base branch
gw add feature/auth -b develop
```

### `gw cd <branch>`

Navigate to existing worktree directory. Works from any worktree or repo root.

```bash
gw cd feature/auth
```

### `gw root`

Navigate back to the main repo root. Works from any worktree.

```bash
gw root
```

### `gw remove <branch>`

Remove worktree (force). Auto cd back to repo root. Symlinks are removed but source files at repo root are untouched.

```bash
gw remove feature/auth
```

### `gw ls`

List all worktrees. Alias: `gw list`.

```bash
gw ls
```

## Directory Structure

```
repo-root/
├── worktrees/
│   ├── feature/
│   │   └── auth/              # worktree checkout
│   │       ├── .env -> ../../../.env
│   │       ├── node_modules -> ../../../node_modules
│   │       └── ...
│   └── fix/
│       └── bug/
├── worktree.yml              # project-level symlink config
~/.worktree.yml               # global symlink config
```

## Claude Code Integration

### WorktreeCreate Hook

Claude Code's built-in worktree (`isolation: "worktree"`) triggers the `WorktreeCreate` hook, which runs `hooks/worktree-symlink.sh` to auto-create symlinks from both global and project `worktree.yml`.

### Manual Workflow

Claude Code **cannot** `cd` into worktrees for you — `cd` in Bash tool only affects the subprocess.

**Recommended:** Create worktree first, then start Claude Code from inside it:

```bash
gw add feature/xyz
claude    # starts session in worktree directory
```

Or use `! gw add feature/xyz` inside Claude Code prompt to run in your terminal.

## Customization

Override worktree base path via environment variable:

```bash
export GW_WORKTREE_BASE="$HOME/worktrees"
```

Default: `$REPO_ROOT/worktrees`

## Error Handling

| Error | Action |
| --- | --- |
| Not a git repo | Exit with error |
| No configs found | No symlinks created (no error) |
| Worktree already exists | Exit with error |
| Worktree not found (cd/remove) | Exit with error |
| Source path missing for symlink | Silently skipped |

## Best Practices

- Add `worktrees/` to `.gitignore`
- Put common symlinks in `~/.worktree.yml` (e.g., `.env`, `node_modules`)
- Put project-specific symlinks in `<repo>/worktree.yml`
- Use worktrees for parallel feature development without stashing
- Remove worktrees when done to keep things clean
