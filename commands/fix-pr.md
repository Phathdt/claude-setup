# Fix PR Review Comments

Fetch review comments, fix issues, reply, and mark as resolved.

## Arguments

$ARGUMENTS

## Instructions

Use the `gh` skill (section "2. Fixing PR Review Comments") to:

1. Get current PR number (or use provided PR number/URL)
2. Fetch review comments via REST API: `gh api repos/:owner/:repo/pulls/{pr}/comments`
3. For each unresolved comment:
   - Display: file, line, comment body, author
   - Ask user: "Fix this? (Yes/No/Skip)"
   - If Yes: Read file, implement fix
4. Commit and push fixes: `fix(pr): address review comments`
5. **CRITICAL - For EACH fixed comment, you MUST do BOTH**:
   a. Reply to comment: `gh api repos/:owner/:repo/pulls/{pr_number}/comments/{comment_id}/replies -f body="Fixed: ..."`
   b. Get thread ID via GraphQL query, then resolve: `gh api graphql -f query='mutation { resolveReviewThread(input: {threadId: "{thread_id}"}) { thread { isResolved } } }'`
6. **NEVER skip resolving threads** - every fixed comment must be replied to AND resolved

## Usage

```
/fix-pr              # Fix comments on current branch's PR
/fix-pr 123          # Fix comments on PR #123
/fix-pr https://github.com/owner/repo/pull/123
```
