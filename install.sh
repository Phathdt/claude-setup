#!/usr/bin/env bash
set -euo pipefail

# Claude Code Team Kit — Installer
# Copies the kit into ~/.claude/ and sets up dependencies.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$HOME/.claude"
BACKUP_DIR="$TARGET/backups/pre-kit-$(date +%Y%m%d%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "========================================="
echo "  Claude Code Team Kit — Installer"
echo "========================================="
echo ""

# -------------------------------------------
# Pre-flight checks
# -------------------------------------------
if ! command -v node &>/dev/null; then
  error "Node.js is required but not found. Install it first."
  exit 1
fi

if ! command -v yarn &>/dev/null && ! command -v npm &>/dev/null; then
  error "yarn or npm is required but not found."
  exit 1
fi

NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
  error "Node.js 18+ is required. Found: $(node -v)"
  exit 1
fi

info "Source: $SCRIPT_DIR"
info "Target: $TARGET"
echo ""

# -------------------------------------------
# Backup existing config
# -------------------------------------------
if [ -d "$TARGET" ]; then
  warn "Existing ~/.claude/ detected."
  read -p "Back up existing config before installing? [Y/n] " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    info "Backing up to $BACKUP_DIR ..."
    mkdir -p "$BACKUP_DIR"
    # Back up key files only (not caches/runtime)
    for item in CLAUDE.md settings.json .kit.json .kitignore .env.example agents commands hooks rules output-styles scripts schemas skills statusline.cjs statusline.sh statusline.ps1; do
      if [ -e "$TARGET/$item" ]; then
        cp -r "$TARGET/$item" "$BACKUP_DIR/" 2>/dev/null || true
      fi
    done
    ok "Backup created at $BACKUP_DIR"
  fi
else
  info "No existing ~/.claude/ found. Creating fresh install."
  mkdir -p "$TARGET"
fi

# -------------------------------------------
# Copy kit files
# -------------------------------------------
info "Copying kit files..."

# Directories
for dir in agents commands hooks rules output-styles schemas scripts skills docs plans; do
  if [ -d "$SCRIPT_DIR/$dir" ]; then
    # Remove existing dir content, then copy fresh
    rm -rf "$TARGET/$dir"
    cp -r "$SCRIPT_DIR/$dir" "$TARGET/$dir"
  fi
done

# Create plans/reports if not exists
mkdir -p "$TARGET/plans/reports"

# Top-level files
for file in CLAUDE.md settings.json .kit.json .kitignore .env.example .gitignore package.json .prettierrc.json .prettierignore statusline.sh; do
  if [ -f "$SCRIPT_DIR/$file" ]; then
    cp "$SCRIPT_DIR/$file" "$TARGET/$file"
  fi
done

ok "Kit files copied."

# -------------------------------------------
# Set executable permissions
# -------------------------------------------
info "Setting permissions..."
find "$TARGET/hooks" -name "*.cjs" -exec chmod +x {} + 2>/dev/null || true
find "$TARGET/hooks" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$TARGET/scripts" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true
find "$TARGET/scripts" -name "*.py" -exec chmod +x {} + 2>/dev/null || true
chmod +x "$TARGET/statusline.sh" 2>/dev/null || true
ok "Permissions set."

# -------------------------------------------
# Install Node.js dependencies
# -------------------------------------------
info "Installing Node.js dependencies..."
cd "$TARGET"
if command -v yarn &>/dev/null; then
  yarn install --silent 2>/dev/null
else
  npm install --silent 2>/dev/null
fi
ok "Node.js dependencies installed."

# -------------------------------------------
# Set up Python venv for skills
# -------------------------------------------
if command -v python3 &>/dev/null; then
  info "Setting up Python venv for skills..."
  if [ ! -d "$TARGET/skills/.venv" ]; then
    python3 -m venv "$TARGET/skills/.venv"
  fi
  if [ -f "$TARGET/scripts/requirements.txt" ]; then
    "$TARGET/skills/.venv/bin/pip" install -q -r "$TARGET/scripts/requirements.txt" 2>/dev/null || true
  fi
  ok "Python venv ready."
else
  warn "Python 3 not found. Some skills may not work without it."
fi

# -------------------------------------------
# Optional: Set up .env
# -------------------------------------------
echo ""
if [ ! -f "$TARGET/.env" ]; then
  read -p "Set up .env file now? (API keys for Gemini, notifications, etc.) [y/N] " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    cp "$TARGET/.env.example" "$TARGET/.env"
    info "Created ~/.claude/.env from template. Edit it with your API keys:"
    echo "  nano ~/.claude/.env"
  fi
else
  info "Existing .env found — skipping."
fi

# -------------------------------------------
# Optional: Set up global MCP servers
# -------------------------------------------
if command -v claude &>/dev/null; then
  # Check if any MCP servers already exist
  EXISTING_MCP=$(claude mcp list 2>/dev/null | grep -c "." || true)
  if [ "$EXISTING_MCP" -lt 2 ]; then
    read -p "Set up global MCP servers? (context7, sequential-thinking, etc.) [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      info "Adding MCP servers (scope: user)..."

      # context7 — library/framework docs lookup
      claude mcp add -s user context7 -- npx -y @upstash/context7-mcp@latest 2>/dev/null && \
        ok "Added: context7" || warn "Failed to add context7"

      # sequential-thinking — step-by-step reasoning
      claude mcp add -s user sequential-thinking -- npx -y @modelcontextprotocol/server-sequential-thinking 2>/dev/null && \
        ok "Added: sequential-thinking" || warn "Failed to add sequential-thinking"

      # chrome-devtools — browser debugging
      claude mcp add -s user chrome-devtools -- npx -y chrome-devtools-mcp@latest 2>/dev/null && \
        ok "Added: chrome-devtools" || warn "Failed to add chrome-devtools"

      # atlassian — Jira/Confluence
      claude mcp add -s user -t http atlassian https://mcp.atlassian.com/v1/mcp 2>/dev/null && \
        ok "Added: atlassian" || warn "Failed to add atlassian"

      ok "MCP servers configured globally."
      info "Verify with: claude mcp list"
    fi
  else
    info "Global MCP servers already configured ($EXISTING_MCP found). Skipping."
  fi
else
  warn "Claude CLI not found. Install it first to configure MCP servers."
  info "After installing Claude CLI, run this script again to configure MCP servers."
fi

# -------------------------------------------
# Summary
# -------------------------------------------
echo ""
echo "========================================="
echo -e "  ${GREEN}Installation Complete!${NC}"
echo "========================================="
echo ""
echo "Installed at: ~/.claude/"
echo ""
echo "What's included:"
echo "  - 9 agent definitions"
echo "  - 8 slash commands (/cmp, /ship, /review-pr, /fix-ci, etc.)"
echo "  - 12 hooks (session mgmt, privacy, quality)"
echo "  - 5 rule sets (dev standards, workflows)"
echo "  - 27 skills (React, Node.js, testing, git, Prisma, Goose, PR review, etc.)"
echo "  - 6 output styles (coding levels)"
echo "  - Statusline (bash/zsh)"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.claude/.env with your API keys (optional)"
echo "  2. Verify MCP servers: claude mcp list"
echo "  3. Start Claude Code in any project directory"
echo ""
echo "Quick test:"
echo "  cd your-project && claude"
echo ""
