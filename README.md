# Claude Code Team Kit

A pre-configured Claude Code setup for Node.js + React teams. Includes agents, slash commands, hooks, skills, and rules for productive AI-assisted development.

## What's Included

| Component         | Count | Description                                                       |
| ----------------- | ----- | ----------------------------------------------------------------- |
| **Agents**        | 9     | Specialized subagents (planner, debugger, tester, reviewer, security-auditor, etc.) |
| **Commands**      | 8     | Slash commands (`/cmp`, `/ship`, `/ship-release`, `/fix-ci`, `/fix-pr`, etc.)       |
| **Hooks**         | 12    | Session management, privacy blocking, quality reminders           |
| **Rules**         | 5     | Development standards, workflows, orchestration protocols         |
| **Skills**        | 27    | React, Node.js, testing, git, Prisma, Goose, databases, PR review, and more        |
| **Output Styles** | 6     | Coding level presets (ELI5 to Expert)                             |
| **Statusline**    | 1     | Real-time session info (bash/zsh)                                 |

## Quick Install

```bash
git clone <this-repo> ~/claude-setup
cd ~/claude-setup
chmod +x install.sh
./install.sh
```

The installer will:

1. Back up your existing `~/.claude/` config (if any)
2. Copy all kit files to `~/.claude/`
3. Install Node.js dependencies (prettier)
4. Set up Python venv for skills
5. Optionally configure `.env` and `.mcp.json`

## Requirements

- **Node.js 18+** (required)
- **Python 3** (recommended, for some skills)
- **yarn** or **npm** (for dependencies)
- **Claude Code CLI** installed (`npm install -g @anthropic-ai/claude-code`)
- **macOS or Linux** (Windows not supported)

## Skills Included

### Dev Workflow

`code-review` · `review-pr` · `cook` · `debug` · `fix` · `test` · `git` · `plan` · `docs`

### Frontend (React + Node.js)

`frontend-development` · `ui-styling` · `web-frameworks` · `web-testing` · `react-best-practices` · `mermaidjs-v11`

### Backend

`backend-development` · `databases` · `prisma` · `goose`

### Utility

`ask` · `brainstorm` · `research` · `scout` · `sequential-thinking` · `docs-seeker` · `repomix` · `preview`

## Slash Commands

| Command     | Description                             |
| ----------- | --------------------------------------- |
| `/cmp`           | Stage, commit, and push current branch           |
| `/commit`        | Generate conventional commit message             |
| `/ship`          | Create branch + PR/MR (GitHub & GitLab)          |
| `/ship-release`  | Cherry-pick commits and ship to release branch   |
| `/review-pr`     | Review PR/MR by URL with parallel agents         |
| `/fix-ci`        | Analyze and fix CI/CD failures                   |
| `/fix-pr`        | Fix PR/MR review comments                        |
| `/fix-test`      | Run tests and fix failures                       |
| `/sync`          | Sync branch with remote                          |

## Hooks

| Hook                          | Trigger                        | Purpose                            |
| ----------------------------- | ------------------------------ | ---------------------------------- |
| `session-init`                | SessionStart                   | Inject project context on startup  |
| `subagent-init`               | SubagentStart                  | Inject context into subagents      |
| `dev-rules-reminder`          | UserPromptSubmit               | Remind about dev rules and paths   |
| `usage-context-awareness`     | UserPromptSubmit / PostToolUse | Track usage and context limits     |
| `descriptive-name`            | PreToolUse (Write)             | Enforce descriptive file names     |
| `scout-block`                 | PreToolUse (Bash/Read/etc.)    | Block access to heavy directories  |
| `privacy-block`               | PreToolUse (Bash/Read/etc.)    | Block access to sensitive files    |
| `post-edit-simplify-reminder` | PostToolUse (Edit/Write)       | Remind to simplify after edits     |
| `cook-after-plan-reminder`    | SubagentStop (Plan)            | Remind to run /cook after planning |
| `task-completed-handler`      | TaskCompleted                  | Handle completed agent tasks       |
| `team-context-inject`         | SubagentStart                  | Inject team context for agents     |
| `teammate-idle-handler`       | TeammateIdle                   | Handle idle team agents            |

## Configuration

### `.kit.json` — Kit configuration

Controls coding level, plan naming, locale, privacy settings, and more.

### `.env` — API keys (optional)

Copy `.env.example` to `.env` and fill in:

- `CONTEXT7_API_KEY` — For docs-seeker skill (library docs lookup)
- `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` — For task completion notifications via Telegram (see setup steps in `.env.example`)

### `.mcp.json` — MCP servers (optional)

Copy `.mcp.json.example` to `.mcp.json` and configure:

- `context7` — Library docs lookup
- `sequential-thinking` — Step-by-step reasoning

## Directory Structure

```
~/.claude/
├── CLAUDE.md              # Main instructions for Claude Code
├── settings.json          # Hook definitions and preferences
├── .kit.json              # Kit configuration
├── .kitignore             # Directories to block from LLM context
├── statusline.sh          # Bash/zsh statusline
├── agents/                # 9 agent definitions
├── commands/              # 8 slash commands
├── hooks/                 # 12 hooks + lib/
│   ├── lib/               # Shared hook utilities
│   └── scout-block/       # Directory blocking modules
├── rules/                 # 5 rule sets
├── output-styles/         # 6 coding level presets
├── schemas/               # JSON schema for .kit.json
├── scripts/               # Utility scripts
└── skills/                # 27 skill directories
```

## Customization

### Add/Remove Skills

Skills are self-contained directories under `skills/`. Each contains a `SKILL.md` and optional `references/` or `scripts/`. Simply add or remove directories.

### Modify Rules

Edit files in `rules/` to adjust development standards, workflow, or orchestration behavior.

## Updating

To update the kit, re-run the installer. It will back up your current config first.

```bash
cd ~/claude-setup && git pull && ./install.sh
```

## License

Internal team use. Not for public distribution.
