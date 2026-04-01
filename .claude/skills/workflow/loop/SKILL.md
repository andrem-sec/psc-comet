---
name: loop
description: Schedule a prompt or skill to run on a recurring interval using CronCreate
version: 0.1.0
level: 2
triggers:
  - "/loop"
  - "run every"
  - "schedule this"
  - "repeat every"
context_files: []
steps:
  - name: Parse
    description: Extract interval and prompt from the command arguments
  - name: Convert
    description: Convert interval to a cron expression
  - name: Schedule
    description: Create the cron job via CronCreate tool
  - name: Execute Now
    description: Run the prompt once immediately — do not wait for the first scheduled fire
---

# Loop Skill

Schedules a prompt or slash command to run on a recurring interval. The job runs locally
via the CronCreate tool — no remote infrastructure required.

**Different from loop-operator:** `loop-operator` manages autonomous multi-step loops with
safety guardrails and escalation gates. `/loop` is simpler — it schedules a single prompt
to repeat at an interval, like a cron job.

## Usage

```
/loop [interval] <prompt or slash command>
/loop 5m /checkpoint
/loop 1h /retro
/loop 30m check if the build is passing and report status
```

If no interval is specified, default is **10 minutes**.

## Interval Parsing

Extract the interval from:
- Leading token: `/loop 5m /checkpoint` → 5 minutes
- Trailing clause: `/loop /checkpoint every 5 minutes` → 5 minutes
- No interval found → default 10 minutes

Supported units: `s` (seconds, min 60), `m` (minutes), `h` (hours), `d` (days)
Minimum granularity: **1 minute**

## Interval → Cron Conversion

| Interval | Cron expression |
|---|---|
| ≤59 minutes | `*/N * * * *` (every N minutes) |
| 1–23 hours | `0 */H * * *` (every H hours, on the hour) |
| 24 hours / 1 day | `0 0 * * *` (daily at midnight) |
| Custom time | Ask user for preferred time if ambiguous |

Examples:
- `5m` → `*/5 * * * *`
- `30m` → `*/30 * * * *`
- `2h` → `0 */2 * * *`
- `1d` → `0 0 * * *`

## Scheduling

Use the `CronCreate` tool with:
- `expression`: the cron string
- `prompt`: the full prompt or slash command to run
- `description`: one-line human-readable description

Confirm with the user before creating if the interval is unusually short (<5m) or the
prompt involves writes or external calls.

## Execute Immediately

After creating the cron job, run the prompt once immediately. Do not make the user wait
for the first scheduled fire.

```
Created: /checkpoint every 5 minutes (cron: */5 * * * *)
Running now for the first time...
[checkpoint output]
```

## Managing Scheduled Loops

To list active loops: use `CronList` tool
To delete a loop: use `CronDelete` tool with the cron ID

## Anti-Patterns

Do not schedule prompts that require interactive input — they will fail unattended.

Do not schedule write-heavy operations at high frequency without the user explicitly
requesting it.

Do not create a loop without confirming the prompt is self-contained (no follow-up
questions expected).

## Mandatory Checklist

1. Verify interval was parsed correctly (or defaulted to 10m)
2. Verify cron expression is valid for the interval
3. Verify CronCreate was called with description
4. Verify prompt was executed once immediately after scheduling
