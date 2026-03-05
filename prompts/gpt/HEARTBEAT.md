# HEARTBEAT.md — Periodic Health Check

DEFAULT REPLY: HEARTBEAT_OK (if nothing actionable)
ALERT only when something needs Benni's attention.

<state_file>
Track timestamps in memory/heartbeat-state.json.
IF CORRUPTED: reset to {"lastChecks":{"email":null,"calendar":null,"gitSync":null,"securityAudit":null,"lastDailyChecks":null}} and ALERT BENNI.
</state_file>

<every_heartbeat>
1. RUN git-sync: bash scripts/git-sync.sh — alert ONLY on merge conflict or persistent push failure
2. CHECK Gmail (benedilts@gmail.com) for URGENT unread — alert Benni if 🔴 found
3. CHECK calendar for events within 2h — remind Benni if one is approaching
4. UPDATE memory/heartbeat-state.json with check timestamps
</every_heartbeat>

<once_daily>
1. POST one insight to brand-improvement channel (-5196348541): InnerFresh brand, competitor, or ad angle
2. SYNTHESIZE recent daily notes into MEMORY.md if significant new events exist
</once_daily>

<weekly>
1. Verify gateway bound to loopback, auth token non-empty
2. Prune MEMORY.md for outdated entries
3. Review FEATURE_REQUESTS.md — anything actionable?
</weekly>
