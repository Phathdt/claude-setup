# GitHub CLI Guide

## Authentication

```bash
gh auth login        # Interactive login
gh auth status       # Check auth state
```

## Pull Requests

### Create PR

```bash
# Basic
gh pr create --base main --head feature-branch --title "feat: add login" --body "Summary"

# With HEREDOC body
gh pr create --base main --title "feat(auth): add OAuth" --body "$(cat <<'EOF'
## Summary
- Added OAuth2 provider support

## Test plan
- [ ] Unit tests pass
- [ ] Manual login test
EOF
)"

# Draft mode
gh pr create --draft --title "WIP: new feature"

# Assign reviewers
gh pr create --reviewer @user1,@user2

# Add labels
gh pr create --label "bug,priority:high"
```

### View/Review PR

```bash
gh pr list                    # List PRs
gh pr view 123                # View PR details
gh pr view 123 --web          # Open in browser
gh pr checkout 123            # Checkout PR locally
gh pr diff 123                # View PR diff
gh pr status                  # Your PRs + reviews
```

### Merge PR

```bash
gh pr merge 123 --squash --delete-branch
gh pr merge 123 --auto        # Auto-merge when checks pass
```

### PR Comments

```bash
gh pr comment 123 --body "LGTM!"
gh api repos/:owner/:repo/pulls/123/comments  # View all
```

## Fixing PR Review Comments

### Fetch Unresolved Threads

```bash
# REST API (simple)
gh api repos/:owner/:repo/pulls/{pr_number}/comments

# GraphQL (with resolution status)
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          path
          line
          comments(first: 10) {
            nodes {
              id
              databaseId
              body
              author { login }
            }
          }
        }
      }
    }
  }
}' -f owner="{owner}" -f repo="{repo}" -F pr={number}
```

### Reply + Resolve (BOTH required per fixed comment)

```bash
# Step 1: Reply
gh api repos/:owner/:repo/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="Fixed: {description}"

# Step 2: Resolve thread
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread { isResolved }
  }
}' -f threadId="{thread_id}"
```

## CI/CD — GitHub Actions

### Check Status

```bash
gh run list --branch $(git branch --show-current) --limit 5
gh pr checks                  # PR-specific checks
```

### View Failed Logs

```bash
# Find failed run
gh run list --status failure --limit 1 --json databaseId,name

# Get failed jobs
gh run view {run_id} --json jobs --jq '.jobs[] | select(.conclusion == "failure") | {id: .databaseId, name: .name}'

# View logs
gh run view {run_id} --job {job_id} --log
gh run view {run_id} --log | grep -E "(Error|FAIL|error:|failed)" -A 5
```

### Rerun Jobs

```bash
gh run rerun {run_id} --failed   # Rerun only failed (recommended)
gh run rerun {run_id}            # Rerun all
gh run watch {run_id}            # Monitor progress
```

## Issues

```bash
gh issue list
gh issue view 42
gh issue create --title "Bug" --body "Description"
gh issue develop 42 -c        # Create branch from issue
```

## Repository

```bash
gh repo view                  # Current repo info
gh browse                     # Open repo in browser
```

## JSON Output

```bash
gh pr list --json number,title,author
gh pr view 123 --json commits,reviews
gh issue list --json number,title --jq '.[].title'
```

## Error Handling

| Error                   | Solution                                       |
| ----------------------- | ---------------------------------------------- |
| `gh: command not found` | Install: `brew install gh`                     |
| `not logged in`         | Run: `gh auth login`                           |
| `no pull request found` | Create PR first or specify PR number           |
| `GraphQL error`         | Check owner/repo/PR number are correct         |
