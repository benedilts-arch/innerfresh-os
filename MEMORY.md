# MEMORY.md - Core Lessons & Preferences

Synthesized preferences and learned patterns. Only loaded in private chats.
This is the most personal file — it stays out of group contexts.

## Personal Contact Info (DM-only)
- **Personal email:** benedilts@gmail.com
- This section exists here instead of USER.md so it only loads in private chats, never in group contexts.

## User Preferences
- **Writing:** Use the humanizer skill for drafts. Benni wants to avoid AI-sounding writing.
- **Tone in DMs:** Informal, friendly, jokey. Friend-first, assistant-second.
- **Time display:** All times shown must be in Asia/Dubai (GMT+4).
- **Reminders:** 2 hours before every calendar event.
- **Morning briefing:** 7am Dubai — calendar + email summary + todos.
- **Content format:** Tight, structured, no padding. Use bullet lists over walls of text.
- **Language:** German or English, Benni switches between both freely.

## Active Integrations
- **Google Calendar + Gmail:** Connected via `gog` CLI. Account: benedilts@gmail.com. Keychain access enabled.
- **Notion:** Connected. API key in `~/.config/notion/api_key`. Savage Advertising System page accessible.
- **Telegram:** Main DM (ID: 6560403362). Groups: brand-improvement (-5196348541), secondary (-5081837089).
- **coding-agent:** Claude Code installed, ready for coding tasks.

## Brands
- **InnerFresh** (try-innerfresh.com): Thyroid support drops. Hero angle: "Gaining weight on 900 calories?" Target: women with thyroid/metabolic dysfunction. 4.8/5, 3k+ reviews, 100k women, 60-day guarantee. Pricing: BUY 1 $44.99, BUY 2 GET 1 FREE $45.99, BUY 3 GET 2 FREE $44.99. Known issue: middle bundle is priced higher than single — conversion killer.
- **Peak Footwear:** Separate ecommerce brand. Email marketing via Mailer Profit ($10k/month retainer, 12-month contract from March 5, 2026).

## Install Todos
- [ ] Notion: fix connection to more workspace pages (currently only Savage Advertising System)
- [ ] Figma: connect when ready — read all docs to understand business context
- [ ] Manus: connect for landing page builds with coding-agent
- [ ] Voice notes: install openai-whisper-api skill for Telegram voice input
- [ ] Google Workspace: enable Gmail API (done 2026-03-05), expand to Drive/Sheets if needed

## Project Plans
- Landing pages: build with Manus + coding-agent once Manus is connected
- brand-improvement channel: daily insights on InnerFresh — competitor research, ad angles, improvement suggestions

## Analysis Patterns
- When asked for a recommendation, pull the data locally and include it in the reply. Don't re-post to messaging.
- When discussing config changes, just make the fix. Skip the accounting of alternative approaches unless asked.
- Duplicate delivery: content already posted is delivered. Don't re-send. Address follow-up questions instead.

## Email Triage Patterns
- **🔴 Urgent:** Chargebacks, disputes, partner communications, payments, tax documents
- **🟡 Important:** Meetings, bookings, shipping, client comms
- **🟢 FYI:** Newsletters, social notifications, marketing emails

## Security & Privacy
- **PII redaction:** Never share personal emails, phone numbers, dollar amounts in group chats.
- **Data tiers:** Confidential (DM-only), Internal (group chats OK), Restricted (external needs approval).
- **Secrets:** Never share credentials unless explicitly requested by name with confirmed destination.
- **Financial data:** Reference directionally only in non-private contexts ("revenue trending up", not actual numbers).

## Operational Lessons
- `gog calendar create` hangs without Keychain access. Fixed: set "Allow all applications" in Keychain Access for gogcli entry.
- Telegram group messages require Privacy Mode disabled via BotFather AND bot removed/re-added to group after the change.
- `groupAllowFrom` IDs must be integers, not strings. Use `openclaw config set channels.telegram.groups` with `requireMention: false` for always-on group responses.
- Anthropic API rate limits are tier-based, not just credit-based. Tier 2 requires ~$40 in cumulative spend.
- `gog auth add` opens a browser OAuth flow — must be run on the Mac Mini directly, not via remote.

## System Health
- Gateway: loopback-only (127.0.0.1:18789), running as LaunchAgent
- Heartbeat: every 30 minutes
- Morning briefing cron: 07:00 Dubai daily

---
*Specific task logs live in daily memory files. This file stays concise.*
