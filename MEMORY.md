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
- **Peak Footwear:** Email marketing via Mailer Profit, $10k/month retainer. **60-day initial term from 2026-03-26** (not 12 months), then month-to-month. 60-day termination notice required. Non-compete: 36 months (flagged — likely about resource-sharing/poaching, not blocking other agencies, but still aggressive).

## Integrations
- Google Calendar + Gmail: `benedilts@gmail.com`, `gog` CLI, Keychain-backed
- Notion: Savage Advertising System connected; API key at `~/.config/notion/api_key`
- coding-agent: Claude Code installed
- Figma: token at `~/.config/figma/token`; REST API is **read-only** (no writes); FigJam board The Singularity Epoche: `https://www.figma.com/board/lffjpKHzEFAA4JeGkZaSoK/The-Singularity-Epoche`
- Whisper: working for voice notes via Telegram
- Meta Ads API: token at `~/.config/meta/access_token` — **short-lived, Benni generates daily** at developers.facebook.com/tools/explorer (ads_read permission)

## Personal Context
- **Lana** — Benni's partner. Cat vaccination handled via PetsFirst.
- Benni was at Noku Phuket through ~2026-03-12.

## Pending
- [ ] Fix InnerFresh BUY 2 GET 1 FREE pricing ($45.99 → should be cheaper than $44.99)
- [ ] Keychain "Allow all applications" for gogcli (background gog in cron jobs)
- [ ] Shopify API token (shop domain + admin token) — needed for creative intelligence
- [ ] Meta long-lived token: need App ID + App Secret for Clawd Analytics app to extend to 60 days
- [ ] Advertorials still to map: Weight Gain, Broken Keys, TSH, 5 Reasons, Quiz
- [ ] Check hypothyroid watchlist when fresh Meta token available — 2 ads near threshold (5+ purchases, CPA <$25)

## Manus Cost Controls
- Burn monitor cron: **PERMANENTLY DELETED** (UUID `98c71993-285c-4502-9e99-d622829d4ebd` — was running every minute, caused ~$36/day burn via Sonnet fallback)
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
- Haiku model ID: `anthropic/claude-haiku-4-5-20251001` (not 3-5). Was blocking gateway startup.
- Haiku model can't be config-level primary; gateway crashes. Use Sonnet as config primary, session override to Haiku at startup.
- Cron job fallbacks expensive: all jobs defaulted to Sonnet when Haiku was unavailable = $50/day burn. Always test with correct model IDs before config deploy.
- `tools.profile` must be `full` for cron jobs — `messaging` causes silent exec failures.
- `gog gmail list` requires a query arg: e.g. `gog gmail list "is:unread"`.
- `openclaw memory index --force` rebuilds memory search index after crash/sync issues.
- Valid `tools.profile` values: minimal, coding, messaging, full.
- Meta API purchase action priority: `offsite_conversion.fb_pixel_purchase` → `purchase` → `omni_purchase`. Use 7d_click / 1d_view attribution to match Ads Manager.

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
- Cortisol/stress → thyroid link
- Perimenopause + thyroid dysfunction
- Hashimoto's + gluten angle
- Gut-thyroid axis
- "Normal TSH but still symptomatic" (doctors miss this)
- Bundle strategy: iodine, selenium, adrenal support, gut health

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
- AVATAR #3 (Plateau Thyroid Dieter Script #3): **$2,241 spend, 157 purchases, 3.7 ROAS** — the monster performer. Currently on `/5-reasons`, but copy voice/mechanism perfectly match `/hypothyroid`. Misalignment = performance leak.
- Copy-advertorial fit is a leverage point: misaligned copies see 30-50% ROAS drops. Full 645-ad mapping in progress to identify misfits + expansion opportunities.
- Subscription AOV collapsed because 1-month felt like safe test. Need: medical necessity framing + repricing (1mo $44, 3mo $34/mo, annual $29/mo) + testimonials around month 2 breakthroughs.
- Key advertorial URLs locked: `/hypothyroid`, `/doctor`, `/tsh`, `/weight-gain`, `/broken-keys`, `/5-reasons`, `/quiz-1-0`

---

## Creative Intelligence System (InnerFresh)

### Meta Ad Account Restructure (in progress — 2026-03-07)
**Status:** 702 ads mapped, 131 unique copy themes identified, copy × advertorial fit analysis 60% complete.

**Key Framework:** One campaign per advertorial (7 total). Every ad must pass 2 filters:
1. Performance: proven CPA/ROAS/spend data (7d_click / 1d_view attribution)
2. Strategic fit: copy voice + avatar + mechanism + offer bridge match advertorial theme

**Pages × Advertorials Logic:**
- Medical authority pages (Dr. Lisa Jones, Dr. Rachel Johnson) → Doctor, TSH, Hypothyroid
- Community/editorial pages (Every Womens Health, WH Insider, Womens Wellbeing) → Weight Gain, Broken Keys, 5 Reasons, Quiz
- Women's Health Insider = primary test page (many winning tests NOT deployed to other pages yet — big gap)

**Output:** Google Sheet with:
- Matrix (color-coded: tested/untested/recommended)
- Launch List (post ID, copy snippet, advertorial tag, page, priority)
- Gaps (WH Insider winners → other pages)
- Watchlist (22 ads at 5+ purchases, CPA <$25)

**Activation needed:** Meta API long-lived token + refreshed spend/CPA data per ad.

### Notion: Creative Database
Per winning creative (CPA <$30, 3+ Conversions):
- Creative visual/screenshot
- Full copy: Hook, Body, CTA
- Angle category (matches advertorial)
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

### Data Files (workspace/data/creatives/ and data/)
- `meta_ads_basic.json` — all 702 ads
- `meta_adsets_raw.json` — all ad sets
- `meta_insights_v3.json` — purchase/CPA data (7d_click attribution)
- `meta_creatives_map.json` — post IDs + 200-char copy previews
- `meta_unique_copies.json` — 131 unique copy themes with FULL body text
- `hypothyroid_watchlist.json` — 22 ads monitored for 5+ purchases & CPA <$25
- `creatives/thumbnails/` — 30 creative thumbnails downloaded

### Google Sheet (Ad Restructure)
`https://docs.google.com/spreadsheets/d/1KWPaCiTcKHI-0tMyJoLSW4lUfN6IMtAAD62UIr2pEx0`
Tabs: Sheet1 (702 ads), Top Performers, Matrix, Gaps (launch lists by advertorial)

### Advertorial Mapping Progress (as of 2026-03-07)
- ✅ `/hypothyroid` — complete (Tier 1: Image 28, AVATAR #3, SCRIPT #7)
- ✅ `/doctor` — complete (Tier 1: Image 28, Image 21 Zoe Saldana, SCRIPT #7)
- ⏳ `/tsh`, `/weight-gain`, `/broken-keys`, `/5-reasons`, `/quiz-1-0` — pending fresh token

### Activation needed
- Meta Ads API: **long-lived token** (needs App ID + App Secret for Clawd Analytics)
- Shopify API: shop domain + admin API token
- Triple Whale API: API key (optional)

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

## D2C Operating System Frameworks (2026-03-08)

### Decision Rules Engine (Automated)
- **SCALE:** CPA <$30 AND Conversions ≥3 (7d) AND ROAS ≥2.5x → Auto-flag "Scale" | Increase budget 2-3x | Elite: <$20 CPA → 5x scale
- **HOLD:** $30-45 CPA AND Conversions <5 → Test 5 hook variations | Re-measure after 7d | Re-decide (scale or pause)
- **PAUSE:** CPA ≥$60 OR ROAS <$1 OR 0 conversions after $100 spend → Auto-pause immediately | Save spend | Archive for analysis
- **TEST:** Untested page-advertorial combo → Launch $50-100/day | Gather 5+ conversions | Apply rules above

### Page-Advertorial Pairing Logic (Elite D2C Strategy)
- **Medical Authority Pages:** Dr. Lisa Jones, Dr. Rachel Thompson → ONLY Doctor, TSH, Hypothyroid angles
  - Wrong combos: Dr. Lisa + Quiz = wasted spend (off-brand)
  - Misalignment = 30-50% ROAS drop
- **Community/Editorial Pages:** Women's Health Insider, Every Women's Health, Women's Wellbeing → Weight Gain, Broken Keys, 5 Reasons, Quiz
  - Authority angles underperform on community pages (wrong tone)
  - Logical pairs first, expansion second

### Hook Testing Framework (3x Performance Lever)
- Same copy, different opening line = 3x performance differences
- Isolate hooks as own test variable (not grouped with angle)
- When angle performs well: Test 5 hook variations on SAME angle+page combo
- Winner hook → Expand to all pages running that angle
- Test structure: 7 days, 5+ conversions per hook minimum, $300 budget total

### LTV-Based Cohort Scaling (Beyond CPA)
- **Weight Gain Angle:** $187 LTV | 45% retention | Fast conversion (low friction)
- **Doctor/Authority Angle:** $243-267 LTV | 58-68% retention | Slower initial sale (higher conviction)
- **TSH Angle:** $267 LTV | 68% retention | Niche, high-conviction buyers
- Strategy: Scale higher-LTV cohorts even if initial CPA slightly higher ($28-32 vs $20)
- Key insight: TSH wins on LTV, not initial CPA

### Manus Cost Model (2026-03-08)
- **Haiku (Cheap & Fast):** $0.05/task | Use for hooks, captions, UGC briefs, SMS | Daily: 50+ tasks
- **Sonnet (Balanced):** $0.15/task | Use for full advertorials, landing pages, email sequences | Daily: 5-10 tasks
- **Opus (Strategic):** $0.80/task | Use for brand strategy, deep analysis only | Weekly: 2-3 tasks MAX
- **Daily Budget:** ~$4/day (50 Haiku + 8 Sonnet + 0.5 Opus) | Weekly cap: $30 | Batched tasks, never per-request

### Daily Deliverables (Repeatable System)
1. **10 Copy Angles:** Generated 7:15am via Manus + Clawd analysis of yesterday's winners
2. **3 Designer Briefs:** From top 3 angles (visual direction + messaging)
3. **2-3 Landing Page Copies:** Tied to winning ad angles
4. **Morning Briefing:** Top winners, kill list, what to test today
5. **3-5 UGC Script Briefs:** 15-60 sec TikTok/Reels formats from top angles
6. **Daily Email Sequences:** Auto-triggered from winning angles (5 emails each)
7. **Performance Insights:** Real-time analysis with transparent reasoning (why scale/pause/test)

### Testing Framework Matrix
- **Hook Test:** 7d | 5+ conv/hook | Success: 1 hook <$25 CPA | Budget: $300
- **Page Pair Test:** 7d | 5+ conv/page | Success: Both pages <$35 CPA | Budget: $200
- **Audience Test:** 7d | 5+ conv/aud | Success: Best aud <$28 CPA | Budget: $400
- **Creative Test:** 7d | 5+ conv/visual | Success: 1 visual +20% CTR | Budget: $300
- **Channel Test:** 14d | 20+ conversions | Success: ROAS >1.5x | Budget: $1000

### 30-Day Iteration Cycle (Continuous Improvement)
- **Days 1-7:** Launch angle → gather 5+ conversions → measure CPA/ROAS → apply decision rules (scale/hold/pause)
- **Days 8-14:** If HOLD: test 5 hook variants → find best hook → re-measure → reassess (scale or pause)
- **Days 15-21:** If improved CPA <$30: scale budget. If still >$45: pause. Generate new angle variations
- **Days 22-30:** Top winners → email sequences + UGC scripts + SMS versions → expand to new channels/pages
- **Repeat:** Monthly performance review → strategic shifts (new products, channels) → next 30-day roadmap

### Bottleneck Solutions (Operationalization)
1. **Copy Lag (>4h wait):** Manus auto-draft advertorial → Copywriter iterates (saves 2-3 hrs/day, 5x throughput)
2. **Design Delay (>6h wait):** Midjourney auto-draft visuals → Designer polishes (3x speed, fewer revisions)
3. **Video Queue Backlog:** Hire 2nd editor + recruit 5 more UGC creators (scale 5→30 videos/week)
4. **Approval Bottleneck (>1h SLA miss):** Pre-approved templates + decision rules (90% auto-OK, 2h launch vs 8-12h current)
5. **Affiliate Network Stall:** Systematized recruitment + auto-commission tracking → $30k+/month potential
6. **Analytics Lag:** Real-time dashboard auto-flags winners + failures → no manual handoff delay
