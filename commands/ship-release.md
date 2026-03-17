# Ship to Release

Cherry-pick commits onto a release branch and create a PR/MR.

## Arguments

$ARGUMENTS

## Instructions

1. **Detect platform** by running `git remote -v` and checking origin URL:
   - Contains `github.com` → GitHub (use `gh` CLI)
   - Contains `gitlab.com` or other GitLab instance → GitLab (use `glab` CLI)

2. **Parse arguments**:
   - Arguments can be: `[release-tag] [commit-hashes...]`
   - If first argument looks like a version/tag (e.g., `v1.7.0`, `1.7.0`), use it as target release
   - Remaining arguments are commit hashes to cherry-pick
   - If no release tag specified, fetch latest release (step 3)

3. **Fetch target release tag** (only if not specified in arguments):
   - Fetch all tags: `git fetch --tags`
   - List tags sorted by semver descending: `git tag --sort=-v:refname`
   - The **latest release** = highest semver tag (NOT the most recently created tag)
     - Example: if `v1.8.0` exists and `v1.7.9` was created after it, latest is still `v1.8.0`
   - Show top 5 tags sorted by semver and ask the user which release to target (default: highest version)
   - Optionally cross-reference with platform releases:
     - GitHub: `gh release list --limit 5`
     - GitLab: `glab release list --per-page 5`

4. **Determine the release branch**:
   - Fetch remote: `git fetch origin`
   - Check if a remote branch tracking this release exists (e.g., `release/v1.2.3`, `release/1.2.3`)
   - If no release branch exists, create one from the release tag: `git checkout -b release/<tag> <tag>`

5. **Identify commits to cherry-pick**:
   - If commit hashes provided as arguments, use those
   - If no commits specified, show recent commits on current branch (`git log --oneline -20`) and ask the user which commits to cherry-pick
   - Support multiple commits (space-separated hashes)

6. **Create a new branch for the cherry-pick PR**:
   - Branch naming: `hotfix/<short-description>` or `cherry-pick/<tag>-<short-hash>`
   - Base the branch off the release branch/tag

7. **Cherry-pick commits**:
   - Run `git cherry-pick <hash>` for each commit in order
   - If conflicts occur, notify the user and pause for resolution

8. **Push and create PR/MR**:
   - Push branch to remote with `-u` flag
   - Create PR/MR targeting the release branch:
     - GitHub: `gh pr create --title "fix: <description>" --body "..." --base release/<tag>`
     - GitLab: `glab mr create --title "fix: <description>" --description "..." --target-branch release/<tag>`
   - PR body should include: Summary, Cherry-picked commits list, Original PR references if available

## Usage

```
/ship-release                                    # Interactive: choose release + commits
/ship-release abc1234                            # Cherry-pick to latest release
/ship-release abc1234 def5678                    # Cherry-pick multiple commits to latest release
/ship-release v1.7.0 abc1234                     # Cherry-pick to specific release v1.7.0
/ship-release v1.7.0 abc1234 def5678 ghi9012     # Cherry-pick multiple commits to v1.7.0
```
