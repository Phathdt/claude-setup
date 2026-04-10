---
name: review-pr
description: 'Review a GitHub PR or GitLab MR by URL. Fetches diff, performs code review, categorizes issues (high/medium/low), prints report for discussion, then posts confirmed issues to PR/MR. Usage: /review-pr <url>'
argument-hint: '<github-pr-url | gitlab-mr-url>'
version: 1.0.0
---

# Review PR/MR

Review a Pull Request (GitHub) or Merge Request (GitLab) by URL.

## Arguments

`$ARGUMENTS` = the PR/MR URL (required).

If no arguments provided, use `AskUserQuestion` with question: "Paste the GitHub PR or GitLab MR URL to review."

## Workflow

### Step 1: Parse URL & Detect Platform

Parse `$ARGUMENTS` to extract platform, project, and PR/MR number.

**GitHub patterns:**
- `https://github.com/{owner}/{repo}/pull/{number}`
- `gh pr view` format

**GitLab patterns:**
- `https://gitlab.com/{group}/{subgroup}/{project}/-/merge_requests/{iid}`
- `https://{custom-host}/{path}/-/merge_requests/{iid}`

**Detection rule:**
- URL contains `github.com` → GitHub → use `gh` CLI
- URL contains `gitlab` → GitLab → use `glab` CLI

### Step 2: Create Worktree & Gather Context

**IMPORTANT:** Reviewing only the diff is insufficient — you MUST read full source files to understand context. Use a git worktree to isolate the review — never checkout/switch branches in the main working directory.

#### 2a. Get PR/MR metadata & extract branches

```bash
# GitHub — extract baseRefName (target) and headRefName (source)
gh pr view {number} --json title,body,baseRefName,headRefName,additions,deletions,changedFiles,author

# GitLab
glab mr view {iid}
```

From the response, extract:
- `{target_branch}` = `baseRefName` (e.g., `main`, `develop`)
- `{source_branch}` = `headRefName` (e.g., `feature/auth`)

#### 2b. Create worktree for source branch

```bash
# Fetch latest — both target and source branches
git fetch origin {target_branch} {source_branch}

# Create isolated worktree for the source branch (does NOT affect current branch)
WORKTREE_PATH=$($HOME/.claude/scripts/git-worktree.sh add {source_branch} | tail -1)

# Pull latest in the worktree
git -C "$WORKTREE_PATH" pull origin {source_branch}
```

All subsequent file reads and verification checks use `$WORKTREE_PATH` as the working directory.

#### 2c. Get the diff between target and source branch

```bash
# Diff source branch against its target (base) branch
git -C "$WORKTREE_PATH" diff origin/{target_branch}...origin/{source_branch} --stat
git -C "$WORKTREE_PATH" diff origin/{target_branch}...origin/{source_branch}
```

#### 2d. Read full source of changed files

For each changed file, read from `$WORKTREE_PATH`:
1. **Read the full file** — not just diff hunks — to understand surrounding context
2. **Trace imports/dependencies** — read utility functions, shared hooks, types, configs referenced by changed code
3. **Verify before flagging** — if code uses a library feature (e.g., dayjs plugins, ORM config), check that the setup actually exists before reporting as missing

This avoids false positives like "plugin might not be configured" when it already is.

#### 2e. Cleanup worktree after review

After the entire review is complete (after Step 7 or if user skips posting):

```bash
# Remove worktree — does NOT delete the remote branch
$HOME/.claude/scripts/git-worktree.sh remove {source_branch}
```

**If diff is too large (>5000 lines):** Focus on changed files list first, then review file-by-file for critical files. Summarize skipped files.

### Step 3: Verification Checks

Before code review, run verification checks inside `$WORKTREE_PATH`. Run checks in parallel.

**Auto-detect available checks** by scanning for config files in the repo root:

| Config File | Check | Command (common defaults) |
|-------------|-------|---------------------------|
| `package.json` (scripts.build) | Build | `npm run build` or `yarn build` |
| `package.json` (scripts.lint) | Lint | `npm run lint` or `yarn lint` |
| `package.json` (scripts.format) | Format | `npm run format:check` or `npx prettier --check .` |
| `package.json` (scripts.test) | Test | `npm run test` or `yarn test` |
| `tsconfig.json` | TypeScript | `npx tsc --noEmit` |
| `Makefile` | Build/Lint/Test | `make build`, `make lint`, `make test` |
| `pyproject.toml` / `setup.py` | Python | `pytest`, `ruff check .`, `mypy .` |
| `.golangci.yml` | Go | `go build ./...`, `golangci-lint run`, `go test ./...` |

**Rules:**
- Only run checks that have corresponding config/scripts — don't guess
- Run checks in parallel where possible (build first, then lint/format/test)
- If a check fails, record it but continue with remaining checks
- If no check configs found, skip this step and note "No verification configs detected"

**Output format for Step 6:**

```
### Verification

| Check | Status | Details |
|-------|--------|---------|
| Build | ✅ Pass | `npm run build` — exit 0 |
| Lint | ❌ Fail | 3 errors in src/services/eligibility.ts |
| Format | ✅ Pass | `prettier --check .` — all files formatted |
| TypeScript | ✅ Pass | `tsc --noEmit` — no type errors |
| Test | ⚠️ Partial | 48/50 passed, 2 failed (see details) |
```

If any check fails, include the error output (truncated to 20 lines) below the table.

### Step 4: Code Review (Parallel Agents)

Dispatch **two subagents in parallel**. Each agent receives the diff AND the `$WORKTREE_PATH` to read full source files.

**Agents MUST read full source files** — not just diff hunks — to verify context before flagging issues. If a function uses a library feature, trace the import chain to confirm whether the setup/config exists.

#### Agent 1: `code-reviewer` — Code Quality & Logic

Focuses on:
- Logic errors and bugs
- Performance issues (N+1 queries, memory leaks, unnecessary loops)
- Error handling gaps
- Race conditions / concurrency issues
- API contract violations
- Breaking changes without migration
- Code quality and patterns

#### Agent 2: `security-auditor` — Security & Threat Modeling

Focuses on:
- Security vulnerabilities (injection, XSS, SSRF, path traversal, RCE)
- Authentication / authorization bypass
- Secrets exposure (hardcoded keys, tokens, passwords)
- Input validation and sanitization
- Data exposure in logs or error messages
- Dependency vulnerabilities
- Trust boundary violations

#### Merging Results

After both agents complete, **merge their findings** into a single deduplicated list. If both agents flag the same issue, keep the more detailed one.

#### Issue Classification

Categorize every issue with sequential ID per severity:

| Prefix | Severity | Criteria | Action Required |
|--------|----------|----------|-----------------|
| **H** | **HIGH** | Security vuln, data loss risk, crash/exception, breaking change, auth bypass, secrets exposure | Must fix before merge |
| **M** | **MEDIUM** | Logic error, performance issue (N+1), missing error handling, poor patterns | Should fix before merge |
| **L** | **LOW** | Code style, naming, minor optimization, documentation, suggestions | Nice to have |

**Issue ID format:** `{prefix}{sequential_number}` — e.g., H1, H2, M1, M2, L1, L2

For each issue, provide:
- Issue ID (H1, M1, L1, etc.)
- File path and line number(s)
- Source agent (`code-reviewer` or `security-auditor`)
- Description of the issue
- Suggested fix (code snippet if applicable)

### Step 5: Generate Review Summary

Format the review output as:

```markdown
## Code Review Summary

**PR/MR:** {title} (#{number})
**Author:** {author}
**Changes:** +{additions} -{deletions} across {files} files

### Verification

| Check | Status | Details |
|-------|--------|---------|
| Build | ✅ Pass | ... |
| Lint | ✅ Pass | ... |
| TypeScript | ✅ Pass | ... |
| Test | ✅ Pass | ... |

### Verdict: {APPROVE | REQUEST_CHANGES | COMMENT}

### Details

Each issue listed with ID, file, line, source, description, and suggested fix.
Group by severity: HIGH (H1, H2...) first, then MEDIUM (M1, M2...), then LOW (L1, L2...).
HIGH issues include code snippets showing current vs fixed code.
MEDIUM issues get brief explanation with fix suggestion.
LOW issues get one-line description.

### What Looks Good
- {Positive observations about the code}

### Summary

| Severity | Count | Action |
|----------|-------|--------|
| 🔴 High | {count} | Must fix |
| 🟡 Medium | {count} | Should fix |
| 🟢 Low | {count} | Optional |
| **Total** | **{total}** | |
```

### Step 6: Print Report & Discuss

**IMPORTANT: NEVER post comments directly to GitHub/GitLab without user confirmation.**

Display the full review summary in the terminal. Then ask the user:

```
Review complete. What would you like to do?
1. Post all findings as a review comment
2. Select specific issues to post (by ID, e.g. H1, M2, L3)
3. Edit/remove issues before posting
4. Skip posting — just keep the local report
```

Wait for user response. The user may:
- Disagree with some findings → remove them
- Want to rephrase an issue → edit the description
- Add context or adjust severity
- Confirm all or a subset to post

### Step 7: Post Review Comment (After User Confirmation)

Only proceed after user explicitly confirms which issues to post.

#### Verdict Logic

- **No HIGH or MEDIUM issues in confirmed set** → `APPROVE`
- **MEDIUM issues only** → `COMMENT` (with suggestions)
- **Any HIGH issue** → `REQUEST_CHANGES`

#### GitHub — Post Review

```bash
gh pr review {number} --repo {owner}/{repo} \
  --{approve|request-changes|comment} \
  --body "$(cat <<'EOF'
{confirmed_review_summary_markdown}
EOF
)"
```

#### GitLab — Post Review Comment

```bash
glab mr note {iid} --repo {group/project} -m "$(cat <<'EOF'
{confirmed_review_summary_markdown}
EOF
)"
```

### Step 8: Report to User

Display confirmation with:
- Posted verdict (approve/request changes/comment)
- Number of issues posted vs total found
- Link to the posted comment

## Error Handling

| Error | Action |
|-------|--------|
| Invalid URL format | Ask user for correct URL |
| `gh`/`glab` not installed | Tell user to install: `brew install gh` or `brew install glab` |
| Not authenticated | Tell user to run `gh auth login` or `glab auth login` |
| PR/MR not found | Verify URL and permissions |
| Diff too large (>10k lines) | Review critical files only, note skipped files |

## References

- `references/review-checklist.md` — Detailed review checklist by category
- `references/severity-guidelines.md` — Issue severity classification guide
