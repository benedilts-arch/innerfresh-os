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

## Manus Cost Controls
- Burn monitor cron: UUID `98c71993-285c-4502-9e99-d622829d4ebd`, runs every minute
- Threshold: 7 credits/min (~$0.50/min at $0.069/credit) → auto-kills task + alerts Benni
- State file: `data/manus-burn-state.json`
- Credits/dollar ratio: ~14.56 (based on 364 credits = $25 on 2026-03-06)
- To kill a Manus task via API: `DELETE https://api.manus.ai/v1/tasks/{task_id}` with `API_KEY` header
- Never spawn multiple Manus tasks for same output — one at a time
- Manus only for: building landing pages, deep research, advertorial copy — NOT data analysis

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

### Subscription AOV Insight (2026-03-07)
People taking 1-month sub ($30) see it as "safe test," not commitment. Revenue problem.
- Thyroid takes 8-12 weeks to respond — copy should mirror this science
- Reprice structure: $44/1mo | $39/mo for 3mo | $34/mo for 3mo
- Alternative: split pay option ($20/mo × 3 months) removes upfront barrier, same revenue
- Better guarantee on 3-month (signals confidence, filters for believers)
- Key insight: Filter for believers (thyroid dysfunction believers commit longer), not just clickers

### Ad Account Restructure (2026-03-07)
- **Pages:** 5 editorial/health pages (Dr. Lisa Jones, Dr. Rachel Johnson, Every Womens Health, Womens Health Insider, Womens Wellbeing)
- **Advertorials:** 7 angles (TSH, Doctor, Weight Gain, Broken Keys, 5 Reasons, Hypothyroid, Quiz)
- **Strategy:** Medical authority pages get medical angles, editorial pages get emotional/educational
- **Biggest gap:** WH Insider tests not deployed to other pages (untested opportunity)
- **Monster ad:** AVATAR #3 + Image 28 (Doctor Sorry) = $2,241 spend, 157 purchases, 3.7 ROAS
- **Process:** Copy-to-advertorial mapping via Google Sheet (read copy voice/avatar/mechanism, tag to matching advertorial)
- **Live watchlist:** hypothyroid_watchlist.json monitoring 22 ads for 5+ purchases <$25 CPA

### Learning Log
*(Append winners and losers here as they're tested)*

---

## Creative Intelligence System (InnerFresh)

### Notion: Creative Database
Per winning creative (CPA <$30, 3+ Conversions):
- Creative visual/screenshot
- Full copy: Hook, Body, CTA
- Angle category
- Destination URL + Landing Page CVR/CPA
- Which URL gets most spend, which converts best
- 5 new copy variations generated by Clawd
- Creative brief for video/design team

### Daily Performance Brief (7:30am)
- 🟢 Winner des Tages (Creative | Angle | URL | CPA | Spend)
- 🔴 Kill-Liste
- 📈 URL Performance (Spend | CVR | CPA per landing page)
- 🧪 Laufende Tests
- 💡 Insight des Tages (Clawd Analyse)

### Activation needed
- Meta Ads API: ad account ID + long-lived access token
- Shopify API: shop domain + admin API token
- Triple Whale API: API key

## Pläne
- **Manus verknüpfen** + Landing Pages mit coding-agent bauen
- **brand-improvement channel:** daily InnerFresh insights to `-5196348541`

## Cost Controls (Finalized 2026-03-07)
- **Default model:** `anthropic/claude-haiku-4-5-20251001` — every session, no exceptions
- **Sonnet/Opus:** only on explicit request ("use sonnet" / "switch to sonnet") — auto-switch back to Haiku after task
- **Cost warning:** flag any interaction estimated >$0.01 at start of reply
- **Session management:** sessions >50k tokens get expensive fast ($0.15–0.40/msg input). Compact old notes into MEMORY.md, start fresh session when context bloats.
- **Fallback danger:** if session override fails, falls back to config primary (now Sonnet). Never let Opus in the fallback chain.
- **Cron jobs:** all run Haiku (changed 2026-03-07). manus-burn-monitor deleted (was burning $36/day).
- **Expected daily spend after fixes:** $1–3/day (was $50 due to cron fallback to Sonnet)

## Operational Lessons (2026-03-07 Audit)
- Model name must match Anthropic API exactly: `claude-haiku-4-5-20251001` not `claude-haiku-3-5`
- Gateway can't start with Haiku as config primary (limitation) — use Sonnet as primary, Haiku via session override
- Session context bloat = hidden cost spike. Track token count so future sessions don't inherit bloated contexts
