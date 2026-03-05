# Memory System

## Files

| File | Purpose | When loaded |
|------|---------|-------------|
| `memory/YYYY-MM-DD.md` | Raw daily capture — conversations, events, tasks | Every session (today + yesterday) |
| `MEMORY.md` | Curated patterns, preferences, lessons | Private/DM sessions only |

## Daily Notes
Append-only during the day. Never modify old entries. Never load in group chats.

## MEMORY.md Synthesis
Done by the weekly-memory-synthesis cron (Sundays 3am Dubai) and opportunistically during heartbeats.
- Read last 7 days of daily notes
- Identify durable patterns worth keeping
- Update MEMORY.md with new insights — don't just copy, distill
- Never delete daily note files

## heartbeat-state.json
Tracks last-check timestamps for email, calendar, git sync, security audit.
If corrupted: reset all values to null, rebuild from next run.
