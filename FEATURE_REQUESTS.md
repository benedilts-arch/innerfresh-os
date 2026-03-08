# FEATURE_REQUESTS.md — Ideas for Improvement

Backlog of proposed improvements. Updated from sessions and review councils.

---

## Pending

### [INFRA] meta-performance-sync.sh shadow cron table
- **Problem:** `meta-performance-sync.sh` writes to a `cron_log` table (different schema) instead of `cron-db.sh`'s `cron_runs` table. Meta sync failures are invisible to `diag.sh cron failures` and health alerting.
- **Fix:** Wrap `meta-performance-sync.sh` with `cron-wrap.sh` and remove the inline `log_start()` function. One-line change per AGENTS.md pattern.
- **Risk if ignored:** Meta ad sync can fail silently with no alert reaching Benni.
- **Source:** Innovation Scout 2026-03-08

### [INFRA] Meta access token auto-refresh / expiry guard
- **Problem:** TOOLS.md flags the Meta API token as "short-lived — needs refresh or Long-Lived token setup." No script checks or refreshes it. When it expires, `meta-performance-sync.sh` errors out silently (returns empty TOKEN, exits 1, no Telegram alert since it doesn't use cron-wrap).
- **Fix:** Add `meta-token-check.sh` that (a) calls `GET /me?access_token=TOKEN` and checks for an `error.code=190` expiry error, (b) alerts Benni via `notify.sh` with tier=critical if expired or expiring within 3 days. Add as a daily cron. Long-term: exchange for a 60-day Long-Lived token via `/oauth/access_token?grant_type=fb_exchange_token`.
- **Source:** Innovation Scout 2026-03-08

### [INFRA] Shared credentials.sh library
- **Problem:** Three scripts (`manus-dispatch.sh`, `manus-burn-monitor.sh`, `meta-performance-sync.sh`) each implement their own `cat ~/.config/X/api_key` loading with inconsistent error handling. If credential paths or vault strategy changes, every script needs updating separately.
- **Fix:** Create `scripts/credentials.sh` as a sourceable library with `cred_load <service>` → returns key or exits with logged error. Services: `meta`, `manus`, `notion`. Mirror pattern from `log.sh` (source as library or call as CLI). Reduces future credential refactors to one file.
- **Source:** Innovation Scout 2026-03-08

### Whisper skill for voice notes
- Install `openai-whisper-api` skill from ClawHub
- Requires OpenAI API key
- **Source:** Benni requested

### Figma integration
- Install Figma skill/MCP when Benni provides access
- Goal: read InnerFresh documents for brand context
- **Source:** Benni requested

### Manus integration
- Link Manus for landing page builds with coding-agent
- Credentials: stored in daily memory 2026-03-05
- **Source:** Benni requested

### 2-hour calendar reminders
- Add `--reminder "popup:120m"` to new gog events automatically
- Or: cron that scans upcoming events and adds reminders
- **Source:** User preference

### Daily brand-improvement group post
- Scheduled post to group `-5196348541`
- InnerFresh brand insight, daily
- **Source:** Benni requested

### InnerFresh pricing fix
- BUY 2 GET 1 FREE ($45.99) costs more than BUY 1 ($44.99)
- Fix via Shopify product ID `8139347132490`
- **Source:** Brand audit

### Email categorization improvement
- Current: keyword-based urgency tagging
- Proposed: LLM-based triage using `llm_router.py direct_call`
- Benefit: fewer false positives (Simprosys promo tagged as urgent)

### Morning briefing email scanning
- Current briefing cron doesn't include Gmail scan
- Update UUID `b69e4dfd-78f4-4100-8278-f7ca941f77b1` with email instructions

## Completed

- [x] Google Calendar + Gmail integration
- [x] Notion integration
- [x] Cron automation infrastructure
- [x] Notification priority queue
- [x] LLM usage tracking
- [x] Unified LLM router
- [x] Logging infrastructure
- [x] Financial tracking
- [x] Security hardening
- [x] Memory synthesis cron
