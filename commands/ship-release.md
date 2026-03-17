# Ship to Release

Cherry-pick commits onto a release branch and create a PR/MR.

## Arguments

$ARGUMENTS

## Instructions

1. **Detect platform** by running `git remote -v` and checking origin URL:
   - Contains `github.com` → GitHub (use `gh` CLI)
   - Contains `gitlab.com` or other GitLab instance → GitLab (use `glab` CLI)

2. **Parse arguments**:
   - Arguments can be: `[version] [commit-hashes...]`
   - If first argument looks like a version (e.g., `1.7.0`, `1.8.1`), use it as target release
   - Remaining arguments are commit hashes to cherry-pick
   - If no version specified, auto-detect latest release (step 3)

3. **Fetch target release branch** (only if not specified in arguments):
   - Fetch remote: `git fetch origin`
   - List remote release branches: `git branch -r --list 'origin/release/*' --sort=-v:refname`
   - The **latest release** = highest semver branch (NOT the most recently created)
     - Example: `release/1.8.0` is latest even if `release/1.7.9` was created after it
   - Show top 5 release branches sorted by semver and ask the user which to target (default: highest version)

4. **Checkout the release branch**:
   - Target branch format: `release/<version>` (no `v` prefix)
   - `git checkout release/<version>` and `git pull origin release/<version>`
   - If the release branch doesn't exist remotely, abort and notify user

5. **Identify commits to cherry-pick**:
   - If commit hashes provided as arguments, use those
   - If no commits specified, show recent commits on the source branch (`git log --oneline -20 <source-branch>`) and ask the user which commits to cherry-pick
   - Support multiple commits (space-separated hashes)

6. **Create a new branch for the cherry-pick PR**:
   - Branch naming: `hotfix/<version>-<short-description>`
   - Base the branch off `release/<version>`

7. **Cherry-pick commits**:
   - Run `git cherry-pick <hash>` for each commit in order
   - If conflicts occur, notify the user and pause for resolution

8. **Push and create PR/MR**:
   - Push branch to remote with `-u` flag
   - Create PR/MR targeting the release branch:
     - GitHub: `gh pr create --title "fix: <description>" --body "..." --base release/<version>`
     - GitLab: `glab mr create --title "fix: <description>" --description "..." --target-branch release/<version>`
   - PR body should include: Summary, Cherry-picked commits list, Original PR references if available

## Usage

```
/ship-release                                    # Interactive: choose release branch + commits
/ship-release abc1234                            # Cherry-pick to latest release (e.g., release/1.9.0)
/ship-release abc1234 def5678                    # Cherry-pick multiple commits to latest release
/ship-release 1.7.0 abc1234                      # Cherry-pick to release/1.7.0
/ship-release 1.8.1 abc1234 def5678 ghi9012      # Cherry-pick multiple commits to release/1.8.1
```
