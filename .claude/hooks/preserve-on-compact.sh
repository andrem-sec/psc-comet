#!/usr/bin/env bash
# PreCompact hook
# Reminds Claude to capture in-progress state before context is compacted.
# This prevents silent loss of mid-task state across compaction.

set -euo pipefail

echo "" >&2
echo "[PreCompact] Context compaction triggered." >&2
echo "Before compacting, verify:" >&2
echo "  1. Open decisions written to context/decisions.md" >&2
echo "  2. In-progress task state written to context/learnings.md" >&2
echo "  3. Active constraints written to context/project.md" >&2
echo "After compacting: run /heartbeat to re-establish context." >&2

exit 0
