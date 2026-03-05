# MEMORY.md — Synthesized Preferences & Learned Patterns

LOAD IN PRIVATE/DIRECT CONVERSATIONS ONLY.
NO RULES RESTATED HERE — rules live in AGENTS.md.

<user_preferences>
- Tone in DMs: informal, jokey, friend-first
- All times: Asia/Dubai (GMT+4) — ALWAYS
- Calendar reminders: 2h before every event
- Morning briefing: 7am Dubai (calendar + email + todos)
- Output format: tight + structured, bullets over paragraphs
- Language: German or English — follow his lead
- Drafts: run through humanizer skill before sending
</user_preferences>

<brands>
InnerFresh (try-innerfresh.com):
- Product: thyroid support drops, target = women with metabolic dysfunction
- Pricing: BUY 1 $44.99 | BUY 2 GET 1 FREE $45.99 (BUG: costs more than BUY 1) | BUY 3 GET 2 FREE $44.99
- Social proof: 4.8/5, 3k+ reviews, 100k women, 60-day guarantee
- Shopify product ID: 8139347132490

Peak Footwear:
- Email marketing via Mailer Profit — $10k/month, 12-month contract from 2026-03-05
- Non-compete clause: 36 months (flagged — too aggressive)
</brands>

<integrations>
- Google Calendar + Gmail: benedilts@gmail.com via gog CLI, Keychain-backed
- Notion: Savage Advertising System page connected, API key at ~/.config/notion/api_key
- coding-agent: Claude Code installed and ready
</integrations>

<install_backlog>
[ ] Figma — connect when ready, read docs for InnerFresh brand context
[ ] Manus — connect for landing page builds with coding-agent
[ ] Whisper skill — voice notes from Telegram
[ ] Morning briefing cron — ADD Gmail scan (cron UUID: b69e4dfd-78f4-4100-8278-f7ca941f77b1)
[ ] Fix InnerFresh BUY 2 GET 1 FREE pricing ($45.99 must be cheaper than $44.99)
</install_backlog>

<operational_lessons>
CRITICAL GOTCHAS — do not repeat these mistakes:
1. gog CLI HANGS in background if Keychain "Allow all applications" is not set on gogcli entry
2. Telegram groups: Privacy Mode changes require bot REMOVAL + RE-ADD after BotFather update
3. openclaw.json groupAllowFrom values MUST BE INTEGERS, not strings
4. Anthropic Tier 2: requires ~$40 CUMULATIVE SPEND, not just credit balance
5. macOS bash 3.2: NO date +%s%3N and NO ${VAR^} — use python3 for both
6. openclaw cron edit: REQUIRES UUID, not name — save UUIDs when creating jobs
7. pip3 on macOS system Python: REQUIRES --break-system-packages flag
</operational_lessons>

<plans>
- Manus + coding-agent → build InnerFresh landing pages
- brand-improvement channel (-5196348541) → daily InnerFresh insights
</plans>
