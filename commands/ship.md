# Ship Changes

Create a new branch, commit all changes, push to remote, and create a pull/merge request.

## Arguments

$ARGUMENTS

## Instructions

1. **Detect platform** by running `git remote -v` and checking origin URL:
   - Contains `github.com` → GitHub (use `gh` skill)
   - Contains `gitlab.com` or other GitLab instance → GitLab (use `glab` skill)

2. Check `git status` and `git diff --stat` to analyze changes
3. Always create a new branch (generate descriptive name from changes)
4. Stage and commit changes with conventional commit message
5. Push branch to remote with `-u` flag
6. Determine base/target branch (use argument if provided, otherwise auto-detect)
7. Create PR/MR with detailed body (Summary, Changes, Testing sections)

### GitHub

Use `gh` skill (section "1. Creating Pull Requests"):

```bash
gh pr create --title "feat: title" --body "..." --base main
```

### GitLab

Use `glab` skill (section "1. Creating Merge Requests"):

```bash
glab mr create --title "feat: title" --description "..." --target-branch main
```

## Usage

```
/ship              # Auto-detect base/target branch
/ship main         # PR/MR to main
/ship staging      # PR/MR to staging
/ship develop      # PR/MR to develop
```
