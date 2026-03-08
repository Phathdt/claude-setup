---
name: git
description: 'Git operations with conventional commits and platform-aware GitHub/GitLab workflows. Use for staging, committing, pushing, PRs/MRs, merges, fixing review comments, CI/CD troubleshooting. Auto-detects GitHub (gh) or GitLab (glab) from git remote.'
argument-hint: 'cm|cp|pr|merge [args]'
version: 2.0.0
---

# Git Operations

## Platform Detection

**Auto-detect platform before any PR/MR, review, or CI operation:**

```bash
git remote -v | grep origin | head -1
```

- Contains `github.com` → **GitHub** → use `gh` CLI (see `references/github-cli-guide.md`)
- Contains `gitlab.com` (or other GitLab host) → **GitLab** → use `glab` CLI (see `references/gitlab-cli-guide.md`)

## Default (No Arguments)

If invoked without arguments, use `AskUserQuestion` to present available git operations:

| Operation | Description                          |
| --------- | ------------------------------------ |
| `cm`      | Stage files & create commits         |
| `cp`      | Stage files, create commits and push |
| `pr`      | Create Pull/Merge Request            |
| `merge`   | Merge branches                       |

Execute git workflows via `git-manager` subagent to isolate verbose output.

**IMPORTANT:**

- Sacrifice grammar for the sake of concision.
- Ensure token efficiency while maintaining high quality.
- Pass these rules to subagents.

## Arguments

- `cm`: Stage files & create commits
- `cp`: Stage files, create commits and push
- `pr`: Create PR/MR [to-branch] [from-branch]
  - `to-branch`: Target branch (default: main)
  - `from-branch`: Source branch (default: current branch)
- `merge`: Merge [to-branch] [from-branch]
  - `to-branch`: Target branch (default: main)
  - `from-branch`: Source branch (default: current branch)

## Quick Reference

| Task            | Reference                            |
| --------------- | ------------------------------------ |
| Commit          | `references/workflow-commit.md`      |
| Push            | `references/workflow-push.md`        |
| Pull Request    | `references/workflow-pr.md`          |
| Merge           | `references/workflow-merge.md`       |
| Standards       | `references/commit-standards.md`     |
| Safety          | `references/safety-protocols.md`     |
| Branches        | `references/branch-management.md`    |
| GitHub CLI      | `references/github-cli-guide.md`     |
| GitLab CLI      | `references/gitlab-cli-guide.md`     |
| CI Error Patterns | `references/ci-error-patterns.md`  |

## Core Workflow

### Step 1: Stage + Analyze

```bash
git add -A && git diff --cached --stat && git diff --cached --name-only
```

### Step 2: Security Check

Scan for secrets before commit:

```bash
git diff --cached | grep -iE "(api[_-]?key|token|password|secret|credential)"
```

**If secrets found:** STOP, warn user, suggest `.gitignore`.

### Step 3: Split Decision

**NOTE:**

- Search for related issues on GitHub/GitLab and add to body.
- Only use `feat`, `fix`, or `perf` prefixes for files in `.claude` directory (do not use `docs`).

**Split commits if:**

- Different types mixed (feat + fix, code + docs)
- Multiple scopes (auth + payments)
- Config/deps + code mixed
- FILES > 10 unrelated

**Single commit if:**

- Same type/scope, FILES ≤ 3, LINES ≤ 50

### Step 4: Commit

```bash
git commit -m "type(scope): description"
```

## Output Format

```
✓ staged: N files (+X/-Y lines)
✓ security: passed
✓ commit: HASH type(scope): description
✓ pushed: yes/no
```

## Error Handling

| Error            | Action                      |
| ---------------- | --------------------------- |
| Secrets detected | Block commit, show files    |
| No changes       | Exit cleanly                |
| Push rejected    | Suggest `git pull --rebase` |
| Merge conflicts  | Suggest manual resolution   |

## References

- `references/workflow-commit.md` - Commit workflow with split logic
- `references/workflow-push.md` - Push workflow with error handling
- `references/workflow-pr.md` - PR/MR creation with remote diff analysis
- `references/workflow-merge.md` - Branch merge workflow
- `references/commit-standards.md` - Conventional commit format rules
- `references/safety-protocols.md` - Secret detection, branch protection
- `references/branch-management.md` - Naming, lifecycle, strategies
- `references/github-cli-guide.md` - GitHub CLI (gh) commands reference
- `references/gitlab-cli-guide.md` - GitLab CLI (glab) commands reference
- `references/ci-error-patterns.md` - CI failure patterns and fixes
