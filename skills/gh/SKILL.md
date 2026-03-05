---
name: GitHub CLI Operations
description: This skill should be used when the user asks to "create a PR", "create pull request", "fix PR review", "fix review comments", "check CI status", "check GitHub Actions", "fix CI", "fix pipeline", "rerun failed jobs", "rerun CI", "view PR", mentions "gh pr", "gh run", "GitHub Actions", "pull request", "review comments", "CI failure", or discusses GitHub workflow automation, PR creation, code review fixes, or CI/CD troubleshooting.
version: 1.0.0
---

# GitHub CLI Operations

Comprehensive knowledge for GitHub CLI (`gh`) operations including PR management, code reviews, and CI/CD workflows.

## Overview

This skill provides Claude with knowledge to autonomously handle GitHub operations using the `gh` CLI tool. Claude will use this skill when tasks involve:

- Creating or managing pull requests
- Fixing PR review comments
- Checking and fixing CI/CD failures
- Rerunning failed GitHub Actions jobs

## Prerequisites

Before executing any `gh` commands, verify:

```bash
# Check gh is installed and authenticated
gh auth status
```

If not authenticated, guide user to run `gh auth login`.

---

## 1. Creating Pull Requests

### When to Use

- User has local changes to push as PR
- User says "create PR", "open PR", "submit for review"
- After completing a feature or fix

### Steps

1. **Analyze changes**:

   ```bash
   git status
   git diff --stat
   ```

2. **Create new branch** (if on main/master/develop):

   ```bash
   # Check current branch
   current_branch=$(git branch --show-current)

   # If on protected branch, create new branch
   if [[ "$current_branch" =~ ^(main|master|develop|staging)$ ]]; then
     # Create descriptive branch name based on changes
     git checkout -b feat/descriptive-name
     # Or for fixes:
     git checkout -b fix/issue-description
   fi
   ```

   Branch naming conventions:
   - `feat/feature-name` - New features
   - `fix/bug-description` - Bug fixes
   - `refactor/what-changed` - Refactoring
   - `docs/what-documented` - Documentation
   - `chore/task-name` - Maintenance tasks

3. **Stage and commit changes**:

   ```bash
   git add <specific_files>
   git commit -m "feat: descriptive commit message"
   ```

4. **Push branch to remote**:

   ```bash
   git push -u origin $(git branch --show-current)
   ```

6. **Determine base branch** (in order of priority):
   - If user specifies: use that branch
   - Auto-detect from git log:
     ```bash
     git log --oneline --decorate | grep -E 'origin/(main|master|staging|develop)' | head -1
     ```
   - Check branch config:
     ```bash
     git config --get branch.$(git branch --show-current).merge
     ```
   - Fallback: `main`

8. **Get commit history for PR body**:

   ```bash
   git log --oneline $(git merge-base HEAD origin/{base})..HEAD
   ```

9. **Create PR with detailed body**:

   ```bash
   gh pr create --title "feat: descriptive title" --body "$(cat <<'EOF'
   ## Summary
   - Brief description of what this PR does
   - Key changes and their purpose

   ## Changes
   - List of modified files/areas
   - Implementation details

   ## Testing
   - [ ] Unit tests added/updated
   - [ ] Manual testing performed
   - [ ] CI pipeline passes

   ## Related Issues
   Closes #<issue_number>
   EOF
   )"
   ```

### Title Format

Use conventional commit format:

- `feat: add user authentication`
- `fix: resolve memory leak in parser`
- `refactor: simplify database queries`
- `docs: update API documentation`

---

## 2. Fixing PR Review Comments

### When to Use

- User says "fix review", "address comments", "fix PR feedback"
- PR has unresolved review threads
- After receiving code review

### Steps

1. **Get current PR number**:

   ```bash
   gh pr view --json number --jq '.number'
   ```

2. **Fetch review comments** (REST API - avoids GraphQL deprecation errors):

   ```bash
   # gh auto-detects owner/repo from current directory
   gh pr view {pr_number} --json comments

   # Or use REST API directly
   gh api repos/:owner/:repo/pulls/{pr_number}/comments
   ```

   Note: `:owner/:repo` is auto-replaced by `gh` from current git remote.

   This returns comments with: `id`, `path`, `line`, `body`, `user.login`, `in_reply_to_id`

3. **Fetch unresolved review threads** (GraphQL - if REST not sufficient):

   ```bash
   gh api graphql -f query='
   {
     repository(owner: "{owner}", name: "{repo}") {
       pullRequest(number: {pr_number}) {
         reviewThreads(first: 50) {
           nodes {
             id
             isResolved
             path
             line
             comments(first: 5) {
               nodes {
                 id
                 body
                 author { login }
               }
             }
           }
         }
       }
     }
   }'
   ```

   **Note**: If you get GraphQL deprecation errors, use the REST API approach above.

4. **Filter unresolved threads**: Only process where `isResolved: false`

5. **For each comment/thread**:
   - Display: file, line, comment body, author
   - Ask user: "Fix this? (Yes/No/Skip)"
   - If Yes: Read file, implement fix

6. **Commit and push fixes**:

   ```bash
   git add {fixed_files}
   git commit -m "fix(pr): address review comments"
   git push
   ```

7. **Reply to comment AND resolve thread** (REQUIRED for each fixed comment):

   ```bash
   # Step 1: Reply to the comment explaining the fix
   # IMPORTANT: The endpoint requires the PR number in the path
   gh api repos/:owner/:repo/pulls/{pr_number}/comments/{comment_id}/replies \
     -f body="Fixed: {description of fix}"
   ```

   ```bash
   # Step 2: Resolve the thread (MUST do this after replying)
   gh api graphql -f query='
   mutation {
     resolveReviewThread(input: {threadId: "{thread_id}"}) {
       thread { isResolved }
     }
   }'
   ```

   **IMPORTANT**: Always reply AND mark as resolved after fixing. Never leave threads unresolved.

---

## 3. Checking CI Status

### When to Use

- User says "check CI", "check pipeline", "check status"
- Before merging PR
- After pushing changes

### Steps

1. **Get workflow runs for current branch**:

   ```bash
   gh run list --branch $(git branch --show-current) --limit 5 --json databaseId,name,status,conclusion,createdAt
   ```

2. **Get PR checks** (if PR exists):

   ```bash
   gh pr checks
   ```

3. **Display status table**:

   ```
   | Workflow    | Status     | Conclusion |
   |-------------|------------|------------|
   | CI          | completed  | success    |
   | Tests       | completed  | failure    |
   | Lint        | in_progress| -          |
   ```

4. **If failures exist**: Offer to view logs or fix

---

## 4. Fixing CI Failures

### When to Use

- User says "fix CI", "fix pipeline", "fix GitHub Actions"
- CI/CD workflow has failed
- After seeing red checks on PR

### Steps

1. **Find failed workflow**:

   ```bash
   gh run list --status failure --limit 1 --json databaseId,name,conclusion
   ```

2. **Get failed jobs**:

   ```bash
   gh run view {run_id} --json jobs --jq '.jobs[] | select(.conclusion == "failure") | {id: .databaseId, name: .name}'
   ```

3. **Download logs for failed job**:

   ```bash
   gh run view {run_id} --job {job_id} --log
   ```

4. **Parse error patterns**:
   - Look for: `Error:`, `FAILED`, `TypeError`, `SyntaxError`
   - Extract file paths and line numbers
   - Identify root cause

5. **Display analysis**:

   ```
   Failed Job: test-unit
   File: src/services/user.ts:45
   Error: TypeError: Cannot read property 'id' of undefined
   Suggested Fix: Add null check before accessing property
   ```

6. **Ask user for confirmation** before implementing fix

7. **Apply fix, commit, push**:

   ```bash
   git add {fixed_files}
   git commit -m "fix(ci): {description}"
   git push
   ```

8. **Rerun ONLY failed jobs** (saves CI resources):

   ```bash
   gh run rerun {run_id} --failed
   ```

9. **Monitor progress** (optional):
   ```bash
   gh run watch {run_id}
   ```

---

## 5. Rerunning Failed Jobs

### When to Use

- User says "rerun", "retry failed", "run again"
- Flaky test or transient failure
- After fixing CI issue

### Commands

**Rerun only failed jobs** (recommended):

```bash
gh run rerun {run_id} --failed
```

**Rerun all jobs**:

```bash
gh run rerun {run_id}
```

**Get latest failed run ID**:

```bash
gh run list --status failure --limit 1 --json databaseId --jq '.[0].databaseId'
```

---

## 6. Viewing PR Details

### When to Use

- User says "show PR", "view PR", "PR status"
- Need to understand PR state

### Command

```bash
gh pr view --json number,title,state,body,reviewDecision,statusCheckRollup,mergeable
```

### Display Format

```
PR #123: feat: add user authentication
State: OPEN
Review: APPROVED
Checks: 3/3 passed
Mergeable: Yes
```

---

## Utility Commands

### Get owner/repo (if needed)

```bash
# gh auto-detects from git remote, but if needed explicitly:
git remote -v | grep origin | head -1 | awk '{print $2}' | sed 's/.*github.com[:/]\(.*\)\.git/\1/'

# Or use :owner/:repo placeholder in gh api (auto-replaced)
gh api repos/:owner/:repo
```

### Get current branch

```bash
git branch --show-current
```

### Check if PR exists for current branch

```bash
gh pr view --json number 2>/dev/null && echo "PR exists" || echo "No PR"
```

---

## Error Handling

| Error                   | Solution                                       |
| ----------------------- | ---------------------------------------------- |
| `gh: command not found` | Install: `brew install gh` or `apt install gh` |
| `not logged in`         | Run: `gh auth login`                           |
| `no pull request found` | Create PR first or specify PR number           |
| `GraphQL error`         | Check owner/repo/PR number are correct         |

---

## Best Practices

1. **Always use `--json`** for machine-readable output
2. **Use GraphQL** for complex operations (review threads, mutations)
3. **Use `--failed` flag** when rerunning to save CI resources
4. **Ask before destructive actions** (force push, close PR)
5. **Provide context** in commit messages and PR descriptions
