# Cherry-pick Message

Generate a cherry-pick merge commit message from commit hashes.

## Arguments

$ARGUMENTS

## Instructions

1. **Parse arguments**:
   - Arguments are commit hashes (space or comma separated)
   - Strip commas and whitespace from input
   - At least one commit hash is required

2. **Build commit list**:
   - For each hash, run: `git log --format='- %h %s' <hash> -1`
   - Preserve the order provided by the user

3. **Output the message**:
   - Print the formatted message:
     ```
     cherry-picked from main:
     - <short-hash> <commit-subject>
     - <short-hash> <commit-subject>
     ```
   - Copy-ready — no extra formatting or explanation around it

## Usage

```
/cherry-msg abc1234                          # Single commit
/cherry-msg abc1234 def5678 ghi9012          # Multiple commits
/cherry-msg abc1234, def5678, ghi9012        # Comma separated
```
