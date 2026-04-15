# Check Release

Check if commits have already been cherry-picked to a release branch.

## Arguments

$ARGUMENTS

## Instructions

1. **Detect platform** by running `git remote -v` and checking origin URL:
   - Contains `github.com` → GitHub (use `gh` CLI)
   - Contains `gitlab.com` or other GitLab instance → GitLab (use `glab` CLI)

2. **Parse arguments**:
   - Arguments can be: `[version] [commit-hashes...]`
   - If first argument looks like a version (e.g., `1.7.0`, `1.8.1`), use it as target release
   - Remaining arguments are commit hashes to check
   - If no version specified, auto-detect latest release (step 3)
   - If no commit hashes specified, ask the user which commits to check

3. **Fetch target release branch** (only if not specified in arguments):
   - Fetch remote: `git fetch origin`
   - List remote release branches: `git branch -r --list 'origin/release/*' --sort=-v:refname`
   - The **latest release** = highest semver branch
   - Show top 5 release branches sorted by semver and ask the user which to target (default: highest version)

4. **Fetch release branch log**:
   - Run `git fetch origin release/<version>`
   - Extract all cherry-pick references from merge commit messages:
     ```bash
     git log origin/release/<version> --grep="cherry-picked from main" --format="%H %B"
     ```
   - Parse the commit bodies to collect all short hashes listed under `cherry-picked from main:` sections
   - Build a lookup map: `{ short-hash → merge-commit-hash }`

5. **Check each commit**:
   - For each commit hash provided, normalize to short hash (first 8 chars)
   - Search the lookup map for a match (prefix match — e.g., `fd47f78f` matches `fd47f78`)
   - Also run `git log origin/release/<version> --grep="<short-hash>" --oneline` as a fallback to catch commits referenced anywhere in log messages

6. **Report results**:
   - Display a table with columns: `Commit | Subject | Status | Merged via`
   - Get commit subject: `git log --format='%s' <hash> -1`
   - Status values:
     - `Already in release` — found in cherry-pick message on release branch
     - `Not in release` — not found
   - For "Already in release", show the merge commit hash that brought it in
   - Example output:
     ```
     Release: release/1.4

     | Commit     | Subject                                      | Status             | Merged via |
     |------------|----------------------------------------------|--------------------|------------|
     | fd47f78f   | FITS-1346: prospective clients tab...        | Already in release | c7406f01   |
     | 227b793a   | FITS-1346: align prospective client...       | Already in release | c7406f01   |
     | abc12345   | FITS-1400: new feature                       | Not in release     | —          |
     ```

## Usage

```
/check-release fd47f78f                         # Check single commit against latest release
/check-release fd47f78f 227b793a abc12345       # Check multiple commits against latest release
/check-release 1.4 fd47f78f                     # Check commit against release/1.4
/check-release 1.4 fd47f78f 227b793a            # Check multiple commits against release/1.4
```
