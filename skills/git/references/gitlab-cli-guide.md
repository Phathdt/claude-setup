# GitLab CLI Guide

## Authentication

```bash
glab auth login       # Interactive login (needs api + write_repository scopes)
glab auth status      # Check auth state
```

## Merge Requests

### Create MR

```bash
# Basic
glab mr create --title "feat: add login" --target-branch main --description "Summary"

# Auto-fill from commits
glab mr create --fill

# With HEREDOC body
glab mr create --title "feat(auth): add OAuth" --target-branch main --description "$(cat <<'EOF'
## Summary
- Added OAuth2 provider support

## Test plan
- [ ] Unit tests pass
- [ ] Manual login test
EOF
)"

# Draft mode
glab mr create --draft --title "WIP: new feature"

# Assign reviewers
glab mr create --reviewer user1,user2

# Add labels
glab mr create --label "bug,priority:high"

# Squash + remove branch on merge
glab mr create --squash-before-merge --remove-source-branch
```

### View/Review MR

```bash
glab mr list                  # List MRs
glab mr view                  # View current branch MR
glab mr view 123              # View MR !123
glab mr checkout 123          # Checkout MR locally
glab mr diff 123              # View MR diff
glab mr approve 123           # Approve MR
```

### Merge MR

```bash
glab mr merge 123 --squash --remove-source-branch
```

### MR Comments

```bash
glab mr note 123 -m "LGTM!"                    # Add top-level comment
glab mr note 123 --resolve {note_id}            # Resolve thread by note ID
```

## Fixing MR Review Comments

### Fetch Discussion Threads

```bash
# List all discussions
glab api "projects/:fullpath/merge_requests/{mr_iid}/discussions"

# Filter unresolved only
glab api "projects/:fullpath/merge_requests/{mr_iid}/discussions" | \
  jq '[.[] | select(.notes[0].resolvable == true and .notes[0].resolved == false)]'
```

### Reply + Resolve (BOTH required per fixed comment)

```bash
# Step 1: Reply to thread
glab api --method POST \
  "projects/:fullpath/merge_requests/{mr_iid}/discussions/{discussion_id}/notes" \
  -f body="Fixed: {description}"

# Step 2: Resolve thread
glab api --method PUT \
  "projects/:fullpath/merge_requests/{mr_iid}/discussions/{discussion_id}" \
  -f resolved=true
```

## CI/CD — GitLab Pipelines

### Check Status

```bash
glab pipeline list --ref $(git branch --show-current) --per-page 5
glab ci view                  # Interactive TUI
```

### View Failed Logs

```bash
# Find failed pipeline
glab pipeline list --status failed --per-page 1 --output json

# Get failed jobs
glab pipeline jobs {pipeline_id} --output json | \
  jq '[.[] | select(.status == "failed") | {id: .id, name: .name, stage: .stage}]'

# View job logs
glab ci trace {job_id}
glab ci trace {job_id} 2>&1 | grep -E "(Error|FAIL|error:|failed)" -A 5

# Get job log via API
glab api "projects/:fullpath/jobs/{job_id}/trace"
```

### Retry/Rerun Jobs

```bash
# Retry specific failed job
glab api --method POST "projects/:fullpath/jobs/{job_id}/retry"

# Retry entire pipeline
glab api --method POST "projects/:fullpath/pipelines/{pipeline_id}/retry"

# Trigger fresh pipeline
glab pipeline run --branch $(git branch --show-current)
```

### Validate CI Config

```bash
glab ci lint
```

## API — Arbitrary Requests

```bash
# GET (default)
glab api "projects/:fullpath/merge_requests"

# POST
glab api --method POST "projects/:fullpath/merge_requests" \
  -f source_branch="feat/branch" -f target_branch="main" -f title="MR title"

# PUT
glab api --method PUT "projects/:fullpath/merge_requests/{mr_iid}" \
  -f title="Updated title"
```

`:fullpath` is auto-resolved from git remote (e.g., `group/subgroup/project`).

## CI/CD Variables

```bash
# List
glab api "projects/:fullpath/variables" | jq '.[].key'

# Create
glab api --method POST "projects/:fullpath/variables" \
  -f key="VAR_NAME" -f value="secret" -f protected=true -f masked=true
```

## Error Handling

| Error                     | Solution                                              |
| ------------------------- | ----------------------------------------------------- |
| `glab: command not found` | Install: `brew install glab`                          |
| `not logged in`           | Run: `glab auth login`                                |
| `no merge request found`  | Create MR first or specify MR IID                     |
| `403 Forbidden`           | Check token scopes (needs `api` + `write_repository`) |
| `404 Not Found`           | Check project path / MR IID is correct                |
