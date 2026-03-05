# HEARTBEAT.md

Periodic health check checklist. Keep it actionable and concise.

## Reporting
Heartbeat turns should usually end with NO_REPLY.
Use the notifier scripts with --notify, let them handle one-time failure/recovery delivery:
- Cron failure deltas
- Persistent failure checks
- System health checks
- Data collection health deltas

Only send a direct heartbeat message when the notifier path itself is broken and the user needs intervention.

If memory/heartbeat-state.json is corrupted, replace it with:
`{"lastChecks": {"errorLog": null, "securityAudit": null, "lastDailyChecks": null}}`
Then alert the user.

## Every heartbeat
- Update memory/heartbeat-state.json timestamps for checks performed
- Git backup: run auto-git-sync. If it exits non-zero, log a warning and continue. Alert only for real breakages (merge conflicts, persistent push failures).
- System health check (with --notify so critical issues route with explicit priority)
- Cron failure deltas (with --notify)
- Persistent failure check (with --notify)
- Check Gmail for urgent unread emails (benedilts@gmail.com) — alert Benni if 🔴 Urgent found
- Check upcoming calendar events (<2h away) — remind Benni if one is approaching

## Once daily
- Data collection health deltas (with --notify)
- Repo size check (alert if git repo exceeds 500MB)
- Memory index coverage (alert if below 80% indexed)
- Synthesize recent daily notes into MEMORY.md if new significant events exist
- Post daily insight to brand-improvement channel (-5196348541): one finding about InnerFresh, competitor research, or ad angle recommendation

## Weekly
- Verify gateway is bound to loopback only
- Verify gateway auth is enabled and token is non-empty
- Review and prune MEMORY.md for outdated entries
