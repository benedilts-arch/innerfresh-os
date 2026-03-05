# HEARTBEAT.md — Periodic Health Check

End with HEARTBEAT_OK if nothing actionable. Alert only when something needs attention.

If `memory/heartbeat-state.json` is corrupted, reset to `{"lastChecks":{"email":null,"calendar":null,"gitSync":null,"securityAudit":null,"lastDailyChecks":null}}` and alert Benni.

## Every heartbeat
- Run `bash scripts/git-sync.sh` — alert only if merge conflict or persistent push failure
- Check Gmail (`benedilts@gmail.com`) for 🔴 Urgent unread — alert Benni if found
- Check calendar for events within 2h — remind Benni if one is approaching
- Update `memory/heartbeat-state.json` with check timestamps

## Once daily
- Post one insight to brand-improvement channel (-5196348541): InnerFresh brand, competitor research, or ad angle
- Synthesize recent daily notes into MEMORY.md if significant new events exist

## Weekly (rotate through, don't run all at once)
- Verify gateway still bound to loopback, auth token non-empty
- Prune MEMORY.md for outdated entries
- Review FEATURE_REQUESTS.md — anything actionable?
