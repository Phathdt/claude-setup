# Fix Review Comments

Fetch review comments, fix issues, reply, and mark as resolved.

## Arguments

$ARGUMENTS

## Instructions

1. **Detect platform** by running `git remote -v` and checking origin URL:
   - Contains `github.com` → GitHub (use `gh` skill)
   - Contains `gitlab.com` or other GitLab instance → GitLab (use `glab` skill)

2. Get current PR/MR number (or use provided number/URL)

3. Fetch review comments:
   - **GitHub**: `gh api repos/:owner/:repo/pulls/{pr}/comments`
   - **GitLab**: `glab api "projects/:fullpath/merge_requests/{mr_iid}/discussions"`

4. For each unresolved comment:
   - Display: file, line, comment body, author
   - Ask user: "Fix this? (Yes/No/Skip)"
   - If Yes: Read file, implement fix

5. Commit and push fixes: `fix(review): address review comments`

6. **CRITICAL - For EACH fixed comment, you MUST do BOTH**:

   **GitHub:**
   a. Reply to comment: `gh api repos/:owner/:repo/pulls/{pr_number}/comments/{comment_id}/replies -f body="Fixed: ..."`
   b. Resolve thread: `gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "{thread_id}"}) { thread { isResolved } } }'`

   **GitLab:**
   a. Reply to thread: `glab api --method POST "projects/:fullpath/merge_requests/{mr_iid}/discussions/{discussion_id}/notes" -f body="Fixed: ..."`
   b. Resolve thread: `glab api --method PUT "projects/:fullpath/merge_requests/{mr_iid}/discussions/{discussion_id}" -f resolved=true`

7. **NEVER skip resolving threads** - every fixed comment must be replied to AND resolved

## Usage

```
/fix-pr              # Fix comments on current branch's PR/MR
/fix-pr 123          # Fix comments on PR #123 / MR !123
/fix-pr <url>        # Fix comments from GitHub or GitLab URL
```
