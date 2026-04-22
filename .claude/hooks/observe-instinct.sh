#!/usr/bin/env bash
# Stop Hook: observe-instinct.sh -- RETIRED
#
# Original intent: automatically extract instinct candidates from session activity at stop time.
#
# Why it cannot work: stop hooks receive only {session_id, stop_reason, os, arch} via stdin.
# There is no conversation content, no tool call log, and no session narrative available.
# Automatic pattern extraction is not possible from this hook.
#
# Where observation now happens: inside /wrap-up (step 5, reflect check).
# Claude has full session context during wrap-up and can identify patterns, propose instinct
# candidates, and pipe confirmed ones to instinct-cli.py.
# See: .claude/commands/wrap-up.md and .claude/commands/reflect.md
#
# This file is kept to avoid breaking settings.json hook registrations.
exit 0
