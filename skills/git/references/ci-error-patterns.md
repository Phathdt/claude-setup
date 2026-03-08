# CI Error Patterns Reference

Common CI failure patterns across GitHub Actions and GitLab CI/CD.

## Error Detection Patterns

### JavaScript/TypeScript

```
SyntaxError: Unexpected token                    → missing brackets/semicolons
TypeError: Cannot read property 'x' of undefined → add null checks (obj?.property)
Error: Cannot find module 'package-name'         → npm install, check package.json
```

### Test Failures

```
expect(received).toBe(expected)                  → compare expected vs actual
Timeout - Async callback was not invoked         → increase timeout, fix async
Snapshot name: `-Snapshot +Received`              → update snapshot (jest -u)
```

### Linting / Formatting

```
'variable' is defined but never used             → remove or prefix with _
Code style issues found. Forgot to run Prettier? → npm run format
```

### TypeScript Compilation

```
error TS2345: type 'X' not assignable to 'Y'    → fix type definitions
error TS2339: Property 'x' does not exist        → add proper type annotations
```

### Go

```
undefined: functionName                          → check imports/exports
--- FAIL: TestName                               → check assertion logic
```

### Python

```
ModuleNotFoundError: No module named 'package'   → pip install, check requirements.txt
AssertionError: X != Y                           → check test expectations
```

### Docker / Container

```
ERROR: failed to solve: process did not complete → check Dockerfile commands
permission denied: Docker daemon socket          → check Docker permissions
```

### GitLab CI-Specific

```
project doesn't have any runners online          → check runner registration/tags
Uploading artifacts: too large archive            → reduce artifact size
(.gitlab-ci.yml): mapping values not allowed     → validate with: glab ci lint
```

## Log Analysis

### GitHub Actions

```bash
gh run view {run_id} --job {job_id} --log
gh run view {run_id} --log | grep -E "(Error|FAIL|error:|failed)" -A 5
gh run view {run_id} --json jobs --jq '.jobs[] | select(.conclusion == "failure") | {name, failed_steps: [.steps[] | select(.conclusion == "failure")]}'
```

### GitLab CI

```bash
glab ci trace {job_id}
glab ci trace {job_id} 2>&1 | grep -E "(Error|FAIL|error:|failed)" -A 5
glab api "projects/:fullpath/pipelines/{pipeline_id}/jobs?scope[]=failed" | jq '.[] | {id, name, stage}'
glab ci lint   # Validate .gitlab-ci.yml
```

## Common Fix Patterns

### Dependencies

```bash
rm -rf node_modules package-lock.json && npm install   # Node.js
pip install -r requirements.txt --upgrade              # Python
go mod tidy                                            # Go
```

### Format / Lint

```bash
npm run lint -- --fix && npm run format                 # JS/TS
gofmt -w . && golangci-lint run --fix                  # Go
black . && isort .                                     # Python
```

### Snapshot Updates

```bash
npm test -- -u                                         # Jest / Vitest
```

### Missing CI Variables

```bash
# GitHub
gh secret set SECRET_NAME

# GitLab
glab api --method POST "projects/:fullpath/variables" \
  -f key="SECRET_NAME" -f value="value" -f protected=true -f masked=true
```

## Retry Strategies

### GitHub Actions

```bash
gh run rerun {run_id} --failed    # Rerun only failed (recommended)
gh run rerun {run_id}             # Rerun all
```

### GitLab CI

```bash
glab api --method POST "projects/:fullpath/jobs/{job_id}/retry"       # Retry job
glab api --method POST "projects/:fullpath/pipelines/{pipeline_id}/retry"  # Retry pipeline
glab pipeline run --branch $(git branch --show-current)               # Fresh pipeline
```

## Debugging Tips

1. Check the exact **step/job** that failed, not just the pipeline
2. Look for the **first error** — subsequent errors may be cascading
3. Compare with **passing runs** — what changed?
4. Check **environment differences** — local vs CI
5. Verify **secrets/env vars** are set correctly
6. Check for **flaky tests** — may need retry logic
