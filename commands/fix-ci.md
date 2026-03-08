---
description: Analyze CI/CD pipeline logs and fix issues
---

## CI/CD Pipeline URL

$ARGUMENTS

1. **Detect platform** by running `git remote -v` and checking origin URL:
   - Contains `github.com` → GitHub (use `gh` skill, section "4. Fixing CI Failures")
   - Contains `gitlab.com` or other GitLab instance → GitLab (use `glab` skill, section "4. Fixing CI Failures")

2. Read the CI pipeline/job logs, analyze and find the root causes of the issues, then provide a detailed plan for implementing the fixes.

**IMPORTANT:** Ask the user for confirmation before implementing.
