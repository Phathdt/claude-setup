# Code Review Checklist

## Security

- [ ] No hardcoded secrets, API keys, or credentials
- [ ] SQL/NoSQL queries use parameterized inputs (no string concatenation)
- [ ] User input is validated and sanitized before use
- [ ] Authentication/authorization checks are present and correct
- [ ] No sensitive data logged or exposed in error messages
- [ ] File uploads validated (type, size, path traversal)
- [ ] CORS/CSP headers configured correctly
- [ ] No eval() or dynamic code execution with user input
- [ ] Dependencies don't have known CVEs

## Logic & Correctness

- [ ] Business logic matches requirements/ticket description
- [ ] Edge cases handled (null, empty, boundary values)
- [ ] Off-by-one errors checked in loops and slices
- [ ] Conditional branches cover all cases
- [ ] Return values checked and propagated correctly
- [ ] No dead code or unreachable branches
- [ ] State mutations are intentional and safe

## Error Handling

- [ ] Async operations have try-catch or .catch()
- [ ] Errors provide meaningful messages (not swallowed silently)
- [ ] External API calls handle timeout, 4xx, 5xx responses
- [ ] Database operations handle connection failures
- [ ] File I/O handles missing files and permission errors
- [ ] Graceful degradation when dependencies are unavailable

## Performance

- [ ] No N+1 query patterns (use eager loading / batch queries)
- [ ] Large collections use pagination or streaming
- [ ] No unnecessary loops or redundant computations
- [ ] Database queries use appropriate indexes
- [ ] No memory leaks (unclosed connections, event listeners, streams)
- [ ] Caching used where appropriate (not over-caching)
- [ ] No blocking operations on main thread / event loop

## Concurrency

- [ ] Shared state protected from race conditions
- [ ] Database transactions used for multi-step mutations
- [ ] Optimistic locking or idempotency for critical operations
- [ ] No deadlock potential in lock ordering

## API & Integration

- [ ] API contracts match documentation / OpenAPI spec
- [ ] Breaking changes flagged with migration path
- [ ] Request/response validation at boundaries
- [ ] Backward compatibility maintained (or breaking change documented)
- [ ] Proper HTTP status codes used

## Code Quality

- [ ] Functions/methods have single responsibility
- [ ] No code duplication (DRY)
- [ ] Variable/function names are descriptive
- [ ] Complex logic has explanatory comments
- [ ] No TODO/FIXME without linked ticket
- [ ] Type safety maintained (no unnecessary `any` or type assertions)
