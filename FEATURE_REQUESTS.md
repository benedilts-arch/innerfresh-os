# FEATURE_REQUESTS.md — Ideas for Improvement

Backlog of proposed improvements. Updated from sessions and review councils.

---

## Pending

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
