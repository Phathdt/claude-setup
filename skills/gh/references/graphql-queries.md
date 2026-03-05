# GitHub GraphQL Queries Reference

Common GraphQL queries and mutations for GitHub CLI operations.

## Review Threads

### Fetch All Review Threads
```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          startLine
          diffSide
          comments(first: 10) {
            nodes {
              id
              databaseId
              body
              createdAt
              author {
                login
              }
              replyTo {
                id
              }
            }
          }
        }
      }
    }
  }
}' -f owner="{owner}" -f repo="{repo}" -F pr={number}
```

### Resolve Review Thread
```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  resolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}' -f threadId="{thread_id}"
```

### Unresolve Review Thread
```bash
gh api graphql -f query='
mutation($threadId: ID!) {
  unresolveReviewThread(input: {threadId: $threadId}) {
    thread {
      id
      isResolved
    }
  }
}' -f threadId="{thread_id}"
```

## Pull Request Operations

### Get PR Details with All Info
```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      id
      number
      title
      body
      state
      mergeable
      merged
      isDraft
      reviewDecision
      headRefName
      baseRefName
      author {
        login
      }
      commits(last: 1) {
        nodes {
          commit {
            statusCheckRollup {
              state
              contexts(first: 50) {
                nodes {
                  ... on CheckRun {
                    name
                    status
                    conclusion
                  }
                  ... on StatusContext {
                    context
                    state
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}' -f owner="{owner}" -f repo="{repo}" -F pr={number}
```

### Add Review Comment
```bash
gh api graphql -f query='
mutation($prId: ID!, $body: String!, $path: String!, $line: Int!) {
  addPullRequestReviewThread(input: {
    pullRequestId: $prId
    body: $body
    path: $path
    line: $line
  }) {
    thread {
      id
    }
  }
}' -f prId="{pr_node_id}" -f body="{comment}" -f path="{file_path}" -F line={line_number}
```

### Request Changes
```bash
gh api graphql -f query='
mutation($prId: ID!, $body: String!) {
  addPullRequestReview(input: {
    pullRequestId: $prId
    body: $body
    event: REQUEST_CHANGES
  }) {
    pullRequestReview {
      id
    }
  }
}' -f prId="{pr_node_id}" -f body="{review_body}"
```

### Approve PR
```bash
gh api graphql -f query='
mutation($prId: ID!, $body: String!) {
  addPullRequestReview(input: {
    pullRequestId: $prId
    body: $body
    event: APPROVE
  }) {
    pullRequestReview {
      id
    }
  }
}' -f prId="{pr_node_id}" -f body="LGTM!"
```

## Workflow Operations

### Get Workflow Runs
```bash
gh api repos/{owner}/{repo}/actions/runs \
  --jq '.workflow_runs[:5] | .[] | {id: .id, name: .name, status: .status, conclusion: .conclusion}'
```

### Get Failed Jobs from Run
```bash
gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs \
  --jq '.jobs[] | select(.conclusion == "failure") | {id: .id, name: .name, steps: [.steps[] | select(.conclusion == "failure") | .name]}'
```

### Rerun Failed Jobs
```bash
gh api repos/{owner}/{repo}/actions/runs/{run_id}/rerun-failed-jobs -X POST
```

### Cancel Workflow Run
```bash
gh api repos/{owner}/{repo}/actions/runs/{run_id}/cancel -X POST
```

## Repository Info

### Get Default Branch
```bash
gh api repos/{owner}/{repo} --jq '.default_branch'
```

### Get Branch Protection Rules
```bash
gh api repos/{owner}/{repo}/branches/{branch}/protection \
  --jq '{required_reviews: .required_pull_request_reviews.required_approving_review_count, status_checks: .required_status_checks.contexts}'
```

## Parsing Owner/Repo

### From Remote URL
```bash
gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"'
```

### Extract Separately
```bash
OWNER=$(gh repo view --json owner --jq '.owner.login')
REPO=$(gh repo view --json name --jq '.name')
```

## Tips

1. **Use `-F` for integers**: `-F pr=123` (not `-f pr="123"`)
2. **Use `--jq` for filtering**: Reduces output to what you need
3. **Paginate large results**: Add `first: 100` and handle `pageInfo`
4. **Handle rate limits**: Check `X-RateLimit-Remaining` header
