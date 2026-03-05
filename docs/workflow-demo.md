# Claude Code Team Kit — Workflow Demo

A practical walkthrough of how the kit orchestrates development from idea to merge.

---

## System Overview

```
┌─────────────────────────────────────────────────────┐
│                   Claude Code CLI                    │
│                                                      │
│  User Prompt ──► Hooks Pipeline ──► Agent/Skill      │
│                                                      │
│  ┌──────────┐  ┌──────────┐  ┌───────────────────┐  │
│  │ settings │  │ .kit.json│  │ statusline.sh     │  │
│  │  .json   │  │ (config) │  │ (live telemetry)  │  │
│  └──────────┘  └──────────┘  └───────────────────┘  │
└─────────────────────────────────────────────────────┘
```

**Components at a glance:**

| Layer         | What                            | Count               |
| ------------- | ------------------------------- | ------------------- |
| Hooks         | Event-driven lifecycle handlers | 12 hooks + 11 libs  |
| Agents        | Specialized subagent roles      | 8 agents            |
| Skills        | Callable workflow tools         | 26 skills           |
| Commands      | Slash command shortcuts         | 7 commands          |
| Rules         | Governance & standards          | 5 rule sets         |
| Output Styles | Communication levels            | 6 levels (ELI5→God) |

---

## Installation

```bash
# Clone the kit
git clone <repo-url> claude-setup && cd claude-setup

# Run installer (backs up existing ~/.claude/ first)
./install.sh

# Optional: configure environment
cp .env.example ~/.claude/.env
# Edit with your TELEGRAM_BOT_TOKEN, CONTEXT7_API_KEY, etc.
```

The installer:

1. Checks prerequisites (Node.js 18+, yarn/npm)
2. Backs up existing `~/.claude/` config
3. Copies hooks, agents, skills, commands, rules, scripts, output-styles
4. Sets executable permissions on all shebangs
5. Installs Node.js dependencies
6. Sets up Python venv for skill scripts

---

## Hook Lifecycle

Every interaction flows through a hook pipeline defined in `settings.json`:

```
SessionStart
  └─► session-init.cjs
        • Detect project type (monorepo/single-repo)
        • Load .kit.json config (global → local merge)
        • Resolve active plan from session/branch
        • Write environment to CLAUDE_ENV_FILE

UserPromptSubmit (each prompt)
  ├─► dev-rules-reminder.cjs
  │     • Inject paths, plan context, naming pattern
  │     • Inject language/locale settings
  └─► usage-context-awareness.cjs
        • Fetch OAuth usage limits (60s cache)

PreToolUse (before any tool executes)
  ├─► scout-block.cjs
  │     • Block .kitignore dirs (node_modules, dist, .git)
  │     • Detect overly broad globs (e.g., **/*.js at root)
  │     • Allow build commands (npm, cargo, docker)
  ├─► privacy-block.cjs
  │     • Block .env, credentials, SSH keys
  │     • Allow .env.example, .env.template
  │     • Require APPROVED: prefix for sensitive access
  └─► descriptive-name.cjs
        • Suggest kebab-case for new files

PostToolUse (after edit/write)
  └─► post-edit-simplify-reminder.cjs
        • Track edit count per session
        • Remind about /simplify after 5+ edits

SubagentStart (when spawning agents)
  ├─► subagent-init.cjs
  │     • Inject ~200 tokens context (plan, paths, rules)
  └─► team-context-inject.cjs
        • Inject team membership & peer list

SubagentStop
  └─► cook-after-plan-reminder.cjs
        • Remind to run /cook after plan creation

TaskCompleted
  └─► task-completed-handler.cjs
        • Log progress in team reports

Stop
  └─► notify-telegram.sh
        • Send "session finished" notification
```

---

## Workflow 1: Feature Implementation (`/cook`)

The most common workflow — from idea to merged code.

### Step-by-step

```
User: /cook add user profile avatar upload

  ┌─ 1. INTENT DETECTION ─────────────────────────┐
  │  Analyze input → detect mode:                  │
  │  • --fast → skip research                      │
  │  • --auto → auto-approve (score ≥9.5)          │
  │  • --parallel → multi-agent for 3+ features    │
  │  • (default) → interactive with review gates   │
  └────────────────────────────────────────────────┘
           │
  ┌─ 2. RESEARCH (optional) ──────────────────────┐
  │  Spawn planner-researcher agent:               │
  │  • WebSearch for best practices                │
  │  • Read latest docs via docs-seeker            │
  │  • Analyze existing codebase via repomix       │
  └────────────────────────────────────────────────┘
           │
  ┌─ 3. SCOUT ────────────────────────────────────┐
  │  Spawn parallel Explore agents:                │
  │  • Find related files across codebase          │
  │  • Map dependencies and patterns               │
  │  • Produce scout report                        │
  └────────────────────────────────────────────────┘
           │
  ┌─ 4. PLAN ─────────────────────────────────────┐
  │  Create structured plan:                       │
  │  plans/260305-1719-avatar-upload/              │
  │    ├── plan.md          (overview, ~80 lines)  │
  │    ├── phase-01-api-endpoint.md                │
  │    ├── phase-02-file-storage.md                │
  │    └── phase-03-ui-component.md                │
  └────────────────────────────────────────────────┘
           │
  ┌─ 5. IMPLEMENT ────────────────────────────────┐
  │  Execute each phase:                           │
  │  • frontend-developer → React components       │
  │  • nestjs-expert → API endpoints               │
  │  • Follow plan.md phase order                  │
  └────────────────────────────────────────────────┘
           │
  ┌─ 6. TEST ─────────────────────────────────────┐
  │  Spawn tester agent (mandatory):               │
  │  • Run unit + integration tests                │
  │  • Generate coverage report                    │
  │  • Fix failures → re-run until green           │
  └────────────────────────────────────────────────┘
           │
  ┌─ 7. CODE REVIEW ──────────────────────────────┐
  │  Spawn code-reviewer agent (mandatory):        │
  │  • Scout edge cases first                      │
  │  • Check quality, types, security, performance │
  │  • Max 3 review cycles → auto-approve or ask   │
  └────────────────────────────────────────────────┘
           │
  ┌─ 8. FINALIZE ─────────────────────────────────┐
  │  • docs-manager → update ./docs if needed      │
  │  • git → conventional commit + push            │
  │  • Telegram notification sent                  │
  └────────────────────────────────────────────────┘
```

### Cook modes

| Flag         | Behavior                                           |
| ------------ | -------------------------------------------------- |
| (default)    | Interactive — review gates at each step            |
| `--fast`     | Skip research, fast-track to implementation        |
| `--auto`     | Auto-approve all steps (if score ≥9.5, 0 critical) |
| `--parallel` | Multi-agent for 3+ independent features            |
| `--code`     | Execute existing plan without research/scout       |
| `--no-test`  | Skip testing phase                                 |

---

## Workflow 2: Bug Fixing (`/fix`)

```
User: /fix login form shows 500 error on submit

  1. MODE SELECTION
     • auto (default) — autonomous fix
     • --review — human approval gates
     • --quick — trivial single-file fix
     • --parallel — multiple independent bugs

  2. DEBUG (mandatory — no fix without root cause)
     • Spawn debugger agent
     • Trace call stack backward
     • Verify hypothesis with evidence
     • Classify: simple | moderate | complex

  3. FIX IMPLEMENTATION
     Simple:  direct fix → verify
     Moderate: TaskCreate per step → implement → verify
     Complex: research + brainstorm → plan → implement → verify

  4. VERIFICATION
     • Spawn tester agent → run affected tests
     • Spawn code-reviewer → validate fix quality
     • Confirm no regressions

  5. FINALIZE
     • docs-manager updates if API changed
     • git commit with conventional format
```

---

## Workflow 3: Planning (`/plan`)

```
User: /plan migrate authentication from sessions to JWT

  Modes:
  --auto    Auto-detect complexity (default)
  --fast    Skip research phase
  --hard    2 researchers + red team + validation
  --parallel 2 researchers exploring different approaches
  --two     2+ researchers, compare approaches

  Output:
  plans/260305-1719-jwt-migration/
    ├── plan.md                        # Overview + phase links
    ├── phase-01-jwt-service.md        # JWT token service
    ├── phase-02-auth-middleware.md     # Replace session middleware
    ├── phase-03-refresh-tokens.md     # Token refresh flow
    └── phase-04-migration-script.md   # Data migration

  After plan creation:
  → Hook reminds: "Run /cook --auto plans/260305-1719-jwt-migration/"
```

---

## Workflow 4: Code Review (`/code-review`)

```
User: /code-review

  1. SCOUT EDGE CASES
     • Parallel Explore agents find boundary conditions
     • Map affected files and dependencies

  2. REVIEW CHECKLIST
     • Code quality & readability
     • TypeScript type safety
     • Linting (no syntax errors)
     • Build validation
     • Performance implications
     • Security audit (OWASP top 10)
     • Task completeness vs plan

  3. OUTPUT
     Prioritized findings: Critical → High → Medium → Low
     Metrics: type coverage %, test coverage %, lint issues

  4. FIX CYCLE (max 3 rounds)
     Fix critical/high → re-review → approve or escalate
```

---

## Workflow 5: CI/CD Troubleshooting (`/fix-ci`)

```
User: /fix-ci

  1. Fetch latest GitHub Actions run logs (gh CLI)
  2. Parse error patterns from logs
  3. Spawn debugger for root cause analysis
  4. Implement fix
  5. Push and rerun failed jobs: gh run rerun <id> --failed
```

---

## Workflow 6: PR Lifecycle (`/ship` + `/fix-pr`)

```
# Create PR
User: /ship
  → Check git status
  → Create branch (if on main)
  → Stage + commit (conventional format)
  → Push with -u flag
  → gh pr create with structured body

# Fix review comments
User: /fix-pr
  → Fetch PR review comments
  → Implement each fix
  → Commit + push
  → Reply to comments + resolve threads
```

---

## Agent Roles & When They're Called

```
┌────────────────────┬──────────────────────────────────────┐
│ Agent              │ Called By                             │
├────────────────────┼──────────────────────────────────────┤
│ planner-researcher │ /cook, /plan, /fix (complex)         │
│ brainstormer       │ /brainstorm, /cook (architecture)    │
│ frontend-developer │ /cook (React/UI tasks)               │
│ nestjs-expert      │ /cook (NestJS/backend tasks)         │
│ tester             │ /cook, /fix, /fix-test (mandatory)   │
│ debugger           │ /fix, /debug, /fix-ci, /fix-test     │
│ code-reviewer      │ /cook, /code-review (mandatory)      │
│ docs-manager       │ /cook, /docs (finalize phase)        │
└────────────────────┴──────────────────────────────────────┘
```

---

## Configuration

### `.kit.json` — Master config

```jsonc
{
  "codingLevel": -1, // -1=auto, 0=ELI5, 1=junior, 2=mid, 3=senior
  "privacyBlock": true, // Block .env/credentials access
  "docs": { "maxLoc": 800 }, // Max lines per doc file
  "plan": {
    "namingFormat": "{date}-{issue}-{slug}",
    "validation": "prompt", // Validate plans with 3-8 questions
  },
  "paths": {
    "docs": "docs",
    "plans": "plans",
  },
  "statusline": "minimal", // full | compact | minimal | none
}
```

### Output Styles (coding levels)

| Level | Audience            | Style                                           |
| ----- | ------------------- | ----------------------------------------------- |
| 0     | Zero experience     | Real-world analogies, every line commented      |
| 1     | Junior (0-2 yr)     | Explain WHY before HOW, common pitfalls         |
| 2     | Mid (3-5 yr)        | Design patterns, trade-offs, edge cases         |
| 3     | Senior (5-8 yr)     | Trade-off tables, operational concerns          |
| 4     | Tech Lead (8-15 yr) | Executive summary, risk matrix, business impact |
| 5     | God Mode (15+ yr)   | Minimal prose, code-first, challenge flaws      |

---

## Security Layers

```
Layer 1: scout-block.cjs
  • Blocks node_modules, dist, .git, vendor, __pycache__
  • Detects overly broad globs (prevents context overflow)
  • Allows build commands through (npm, cargo, docker)

Layer 2: privacy-block.cjs
  • Blocks .env, credentials.json, SSH keys, secrets.yaml
  • Allows safe files (.env.example, .env.template)
  • Requires explicit APPROVED: prefix for sensitive access

Layer 3: git skill security scan
  • Scans staged files for API keys, tokens, passwords
  • STOPS commit if secrets detected
```

---

## Session Persistence

Agents maintain context across conversations:

```
[PROJECT_ROOT]/.claude_sessions/
├── planner-researcher/
│   └── 20260305170000_planner-researcher_jwt-migration.json
├── tester/
│   └── 20260305171500_tester_auth-tests.json
├── code-reviewer/
├── debugger/
├── frontend-developer/
├── nestjs-expert/
├── brainstormer/
├── docs-manager/
└── shared_context.md    # Cross-agent state
```

Each session file contains:

- `files_processed` — what was touched
- `key_findings` — discoveries
- `actions_taken` — what was done
- `recommendations` — what to do next
- `cross_agent_notes` — messages for other agents

---

## Quick Reference

| Command               | What it does                         |
| --------------------- | ------------------------------------ |
| `/cook <task>`        | Full feature implementation pipeline |
| `/fix <issue>`        | Debug + fix + verify                 |
| `/plan <task>`        | Create implementation plan           |
| `/code-review`        | Quality/security review              |
| `/ship`               | Create PR                            |
| `/fix-pr`             | Fix PR review comments               |
| `/fix-ci`             | Fix CI/CD failures                   |
| `/fix-test`           | Fix failing tests                    |
| `/commit`             | Generate conventional commit         |
| `/cmp`                | Stage + commit + push                |
| `/sync`               | Sync branch with remote              |
| `/scout <target>`     | Parallel codebase exploration        |
| `/brainstorm <topic>` | Architecture decision analysis       |
| `/ask <question>`     | Expert technical consultation        |
| `/docs init\|update`  | Manage documentation                 |
| `/preview <file>`     | View files or generate visuals       |
