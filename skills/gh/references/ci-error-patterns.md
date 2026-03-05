# CI Error Patterns Reference

Common CI failure patterns and how to identify/fix them.

## Error Detection Patterns

### JavaScript/TypeScript Errors

**Syntax Error**
```
SyntaxError: Unexpected token
```
- Check for missing brackets, semicolons
- Look at the line number in stack trace

**Type Error**
```
TypeError: Cannot read property 'x' of undefined
TypeError: Cannot read properties of undefined (reading 'x')
```
- Add null checks: `obj?.property`
- Verify object exists before accessing

**Reference Error**
```
ReferenceError: x is not defined
```
- Check import statements
- Verify variable is declared

**Module Not Found**
```
Error: Cannot find module 'package-name'
Module not found: Error: Can't resolve 'package-name'
```
- Run `npm install` or `yarn`
- Check package.json dependencies

### Test Failures

**Jest Assertion**
```
expect(received).toBe(expected)
Expected: "expected"
Received: "actual"
```
- Compare expected vs actual values
- Check test logic or implementation

**Timeout**
```
Timeout - Async callback was not invoked within 5000ms
```
- Increase timeout or fix async code
- Check for unresolved promises

**Snapshot Mismatch**
```
Snapshot name: `Component 1`
- Snapshot  - 1
+ Received  + 1
```
- Update snapshot: `jest -u`
- Or fix the component output

### Linting Errors

**ESLint**
```
error  'variable' is defined but never used  @typescript-eslint/no-unused-vars
```
- Remove unused variables
- Or prefix with `_` if intentional

**Prettier**
```
Code style issues found in the above file(s). Forgot to run Prettier?
```
- Run `npm run format` or `prettier --write`

### Build Errors

**TypeScript Compilation**
```
error TS2345: Argument of type 'X' is not assignable to parameter of type 'Y'
error TS2339: Property 'x' does not exist on type 'Y'
```
- Fix type definitions
- Add proper type annotations

**Webpack/Build**
```
Module build failed: Error: ENOENT: no such file or directory
```
- Check file paths
- Verify imports are correct

### Go Errors

**Compilation**
```
undefined: functionName
```
- Check imports and exports
- Verify function exists

**Test Failure**
```
--- FAIL: TestName (0.00s)
    file_test.go:10: expected X, got Y
```
- Check assertion logic

### Python Errors

**Import Error**
```
ModuleNotFoundError: No module named 'package'
```
- Install dependency: `pip install package`
- Check requirements.txt

**Assertion**
```
AssertionError: X != Y
```
- Check test expectations

### Docker/Container Errors

**Build Failed**
```
ERROR: failed to solve: process "/bin/sh -c command" did not complete successfully
```
- Check Dockerfile commands
- Verify base image exists

**Permission Denied**
```
permission denied while trying to connect to the Docker daemon socket
```
- Check Docker permissions
- Run with sudo or add user to docker group

## Log Analysis Commands

### Download Full Logs
```bash
gh run view {run_id} --log > ci-logs.txt
```

### Download Failed Job Logs Only
```bash
gh run view {run_id} --job {job_id} --log-failed
```

### Search for Errors in Logs
```bash
gh run view {run_id} --log | grep -E "(Error|FAIL|error:|failed)" -A 5
```

### Get Step-by-Step Failure
```bash
gh run view {run_id} --json jobs --jq '.jobs[] | select(.conclusion == "failure") | {name: .name, failed_steps: [.steps[] | select(.conclusion == "failure")]}'
```

## Common Fix Patterns

### 1. Dependency Issues
```bash
# Node.js
rm -rf node_modules package-lock.json && npm install

# Python
pip install -r requirements.txt --upgrade

# Go
go mod tidy
```

### 2. Format/Lint Issues
```bash
# JavaScript/TypeScript
npm run lint -- --fix
npm run format

# Go
gofmt -w .
golangci-lint run --fix

# Python
black .
isort .
```

### 3. Test Snapshot Updates
```bash
# Jest
npm test -- -u

# Vitest
npm test -- -u
```

### 4. Type Errors
- Add proper type annotations
- Use type assertions when necessary
- Update type definitions

### 5. Missing Environment Variables
```bash
# Check required env vars in CI config
# Add to GitHub Secrets if needed
gh secret set SECRET_NAME
```

## Rerun Strategies

### Rerun Only Failed Jobs (Recommended)
```bash
gh run rerun {run_id} --failed
```

### Rerun All Jobs
```bash
gh run rerun {run_id}
```

### Rerun with Debug Logging
```bash
gh run rerun {run_id} --debug
```

## Tips for CI Debugging

1. **Check the exact step** that failed, not just the job
2. **Look for the first error** - subsequent errors may be cascading
3. **Compare with passing runs** - what changed?
4. **Check environment differences** - local vs CI
5. **Verify secrets/env vars** are set correctly
6. **Check for flaky tests** - random failures may need retry logic
