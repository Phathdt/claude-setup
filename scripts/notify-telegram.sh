#!/bin/bash
# Telegram notification script for Claude Code hooks
# Reads credentials from ~/.claude/.env or ~/.env

# Source environment variables
if [[ -f "$HOME/.claude/.env" ]]; then
    source "$HOME/.claude/.env"
elif [[ -f "$HOME/.env" ]]; then
    source "$HOME/.env"
fi

# Check if required variables are set
if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
    echo "Telegram notification skipped: TELEGRAM_BOT_TOKEN or TELEGRAM_CHAT_ID not set"
    exit 0
fi

# Get message type from argument (default: "finished")
MESSAGE_TYPE="${1:-finished}"

# Get project name from current directory or git repo name
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    PROJECT_NAME=$(basename "$(git rev-parse --show-toplevel)")
else
    PROJECT_NAME=$(basename "$PWD")
fi

case "$MESSAGE_TYPE" in
    "stop")
        MESSAGE="<b>[$PROJECT_NAME]</b> Claude Code finished working at $(date '+%Y-%m-%d %H:%M:%S')"
        ;;
    "subagent")
        MESSAGE="<b>[$PROJECT_NAME]</b> Claude Code subagent completed task at $(date '+%Y-%m-%d %H:%M:%S')"
        ;;
    *)
        MESSAGE="<b>[$PROJECT_NAME]</b> Claude Code: $MESSAGE_TYPE at $(date '+%Y-%m-%d %H:%M:%S')"
        ;;
esac

# Send notification
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID" \
    -d "text=$MESSAGE" \
    -d "parse_mode=HTML" >/dev/null 2>&1

if [[ $? -eq 0 ]]; then
    exit 0
else
    echo "Failed to send Telegram notification"
    exit 1
fi
