#!/usr/bin/env bash
# Session stop hook — runs when a Claude Code session ends
#
# TODO: Potential uses for this hook:
#   - Validate prototype builds (godot --headless --check-only)
#   - Extract session learnings into memory/skills
#   - Update production/session-state/active.md with final status
#   - Run lint/parse checks on modified .gd files
#   - Archive session logs to production/session-logs/
#   - Trigger a /retrospective or /wrap-up skill automatically

exit 0
