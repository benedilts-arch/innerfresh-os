# MEMORY.md — Synthesized Preferences & Learned Patterns

Only loaded in private/direct conversations. Contains personal context.
No rules restated here — rules live in AGENTS.md.

## User Preferences
- Informal, jokey tone in DMs. Friend-first, assistant-second.
- All times in Asia/Dubai (GMT+4).
- 2h reminder before every calendar event.
- Morning briefing at 7am Dubai: calendar + email + todos.
- Tight, structured output. Bullets over walls of text.
- German or English interchangeably — follow his lead.
- Drafts: run through humanizer skill before sending.

## Brands
- **InnerFresh** (try-innerfresh.com): Thyroid support drops, women + metabolic dysfunction. BUY 1 $44.99, BUY 2 GET 1 FREE $45.99 (bug: costs more), BUY 3 GET 2 FREE $44.99. 4.8/5, 3k+ reviews, 100k women, 60-day guarantee. Product ID `8139347132490`.
- **Peak Footwear:** Email marketing via Mailer Profit, $10k/month retainer, 12-month contract from 2026-03-05. Non-compete: 36 months (flagged, too long).

## Integrations
- Google Calendar + Gmail: `benedilts@gmail.com`, `gog` CLI, Keychain-backed
- Notion: Savage Advertising System connected; API key at `~/.config/notion/api_key`
- coding-agent: Claude Code installed

## Install Backlog
- [ ] Figma — connect when ready, read docs for InnerFresh brand context
- [ ] Manus — connect for landing page builds with coding-agent
- [ ] Whisper skill — voice notes from Telegram
- [ ] Morning briefing cron: add Gmail scan (UUID `b69e4dfd-78f4-4100-8278-f7ca941f77b1`)
- [ ] Fix InnerFresh BUY 2 GET 1 FREE pricing ($45.99 → should be cheaper than $44.99)

## Operational Lessons
- `gog` hangs in background without Keychain "Allow all applications" on gogcli entry.
- Telegram group bot needs Privacy Mode disabled via BotFather + remove and re-add to group.
- `groupAllowFrom` entries must be integers, not strings, in openclaw.json.
- Anthropic Tier 2 needs ~$40 cumulative spend, not just credit balance.
- macOS bash 3.2: no `date +%s%3N`, no `${VAR^}`. Use python3 for both.
- `openclaw cron edit` requires UUID, not name. Save UUIDs when creating jobs.
- pip3 installs need `--break-system-packages` on macOS system Python.

## Brand Intelligence — InnerFresh

### Core Audience
Women who are eating less (some as low as 900 cal/day) and still gaining or can't lose weight. The violation of "calories in/calories out" is their core frustration. They've tried everything. They feel broken. Thyroid/metabolic dysfunction is the reason they've never been told.

### Hero Angle
"Gaining weight on 900 calories?" — the unexpected weight gain angle. Speaks directly to the experience of doing everything right and the body not responding. This is the entry point.

### Proven Hooks (to build on)
- The metabolic dysfunction angle: body isn't burning, not user error
- "I did everything right" frustration
- Doctor dismissal ("your bloodwork is normal") — validation that they're not crazy
- The 60-day guarantee as risk removal

### Brand Voice
- Empathetic, not clinical. She feels heard, not sold to.
- No bro-science. No shame. No "you just need to try harder."
- The product is the solution she hasn't been offered yet.
- Social proof at scale: 100k women, 4.8/5, 3k+ reviews — community, not just product.

### What to Build On
- More angles around specific symptoms: fatigue, brain fog, cold hands/feet, hair loss
- "Why your doctor can't see it" — the testing gap angle
- Before/after story arcs
- Ingredient-level education (what's in it, why it works)

### Learning Log
*(Append winners and losers here as they're tested)*

---

## Pläne
- **Manus verknüpfen** + Landing Pages mit coding-agent bauen
- **brand-improvement channel:** daily InnerFresh insights to `-5196348541`
