# Ship Changes

Create a new branch, commit all changes, push to remote, and create a pull request.

## Arguments

$ARGUMENTS

## Instructions

Use the `gh` skill (section "1. Creating Pull Requests") to:

1. Check `git status` and `git diff --stat` to analyze changes
2. Always create a new branch (generate descriptive name from changes)
3. Stage and commit changes with conventional commit message
4. Push branch to remote with `-u` flag
5. Determine base branch (use argument if provided, otherwise auto-detect)
6. Create PR with detailed body (Summary, Changes, Testing sections)

## Usage

```
/ship              # Auto-detect base branch
/ship main         # PR to main
/ship staging      # PR to staging
/ship develop      # PR to develop
```
