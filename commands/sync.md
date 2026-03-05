# Sync Branch

Checkout and pull the latest code from a remote branch.

## Usage

```
/sync [branch-name]
```

## Arguments

- `branch-name`: (Optional) The branch to checkout and pull. Defaults to `staging`.

## Instructions

1. Parse the arguments: `$ARGUMENTS`
2. Determine the target branch (default: `staging` if no argument provided)
3. Check if there are uncommitted changes:
   - Run `git status --porcelain`
   - If there are changes, warn the user and ask if they want to stash changes first
4. Fetch the latest from remote: `git fetch origin`
5. Checkout the target branch: `git checkout <branch-name>`
6. Pull the latest code: `git pull origin <branch-name>`
7. Report success with current branch and latest commit info

## Example

```bash
# Sync to staging (default)
/sync

# Sync to main branch
/sync main

# Sync to a feature branch
/sync feature/auth
```
