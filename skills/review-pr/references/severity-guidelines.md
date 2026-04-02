# Issue Severity Classification Guide

Issue IDs use prefix + sequential number: **H1, H2, M1, M2, L1, L2, ...**

## 🔴 HIGH (H) — Must Fix Before Merge

Serious issues that will cause problems in production.

### Criteria

- **Security vulnerabilities**: SQL injection, XSS, auth bypass, secrets in code, SSRF, path traversal, IDOR, RCE
- **Data loss or corruption**: Missing transactions, race conditions on writes, cascade deletes without safeguards
- **Crashes / unhandled exceptions**: Null pointer on critical path, unhandled promise rejection that kills process
- **Breaking changes without migration**: Removed API fields, changed response format, schema changes without migration
- **Auth gaps**: Missing auth guard on protected endpoint, privilege escalation, token validation gaps
- **Resource exhaustion**: Unbounded queries, memory leaks on hot paths, missing rate limits on public endpoints

### Examples

```
H1 | src/auth/login.ts:42 | JWT secret hardcoded: `const SECRET = "abc123"`
H2 | src/api/users.ts:18 | User ID from JWT not validated against requested resource (IDOR)
H3 | db/migrations/005.sql | Column dropped without data migration for existing records
```

## 🟡 MEDIUM (M) — Should Fix Before Merge

Issues that will cause problems but don't pose immediate critical risk.

### Criteria

- **Logic errors**: Wrong conditional, incorrect calculation, off-by-one in pagination
- **Missing error handling**: Unhandled async errors, swallowed exceptions, no retry for transient failures
- **Performance problems**: N+1 queries, full table scans, loading entire collection into memory
- **Poor patterns**: God functions, tight coupling, missing input validation at system boundaries
- **Incomplete implementation**: Happy path only, no error states, missing cleanup/rollback
- **Type safety violations**: Excessive `any` usage, unsafe type assertions, missing null checks

### Examples

```
M1 | src/orders/service.ts:87 | N+1 query in loop — fetches user for each order separately
M2 | src/api/handler.ts:23 | Async function missing try-catch, errors will crash request
M3 | src/utils/parse.ts:15 | parseInt without radix, edge case with "0x" prefixed strings
```

## 🟢 LOW (L) — Nice to Have

Issues that improve code quality but don't affect functionality or safety.

### Criteria

- **Code style**: Inconsistent naming, formatting, import ordering
- **Minor optimizations**: Could use Map instead of repeated array.find, unnecessary spread
- **Documentation**: Missing JSDoc on public API, unclear variable names, outdated comments
- **Test coverage**: Missing test for a non-critical branch, redundant test assertions
- **Suggestions**: Better pattern available, modern syntax alternative, cleaner abstraction

### Examples

```
L1 | src/helpers/format.ts:5 | Variable name `d` → rename to `formattedDate`
L2 | src/components/Table.tsx:30 | Could use optional chaining instead of nested ternary
L3 | src/config/index.ts:12 | Magic number 86400 → use named constant SECONDS_PER_DAY
```

## Verdict Decision Matrix

| HIGH | MEDIUM | Verdict |
|------|--------|---------|
| ≥ 1 | any | REQUEST_CHANGES |
| 0 | ≥ 1 | COMMENT |
| 0 | 0 | APPROVE |

## Writing Good Issue Descriptions

**Format:** `{what is wrong} → {why it matters} → {suggested fix}`

**Bad:** "This could be better"
**Good:** "User input passed directly to SQL query without parameterization → allows SQL injection → use parameterized query: `db.query('SELECT * FROM users WHERE id = $1', [userId])`"
