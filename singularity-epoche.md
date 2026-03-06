# The Singularity Epoche
### Master Reference: AI-Assisted Brand Operations
**Benedikt Stransky | InnerFresh + Peak Footwear**
*Last updated: 2026-03-06*

---

## THE VISION

A fully AI-assisted brand operation where every function — copy, ads, analysis, operations, landing pages, creative strategy — has a designated tool, a clear workflow, and a feedback loop that makes the system smarter over time.

No more manual decisions based on gut. Every action is backed by data. Every test becomes a lesson. The system learns and compounds.

---

## 1. TOOL ECOSYSTEM MAP

### 🦞 CLAWD (OpenClaw AI Agent)
**Role:** The operating layer. Runs 24/7, connects everything, executes on command.

**CAN DO:**
- Morning briefings: calendar + inbox summary at 7am
- Cron automation: git sync, backups, health checks, log ingestion
- Brand intelligence reports → brand-improvement Telegram channel
- Copy drafts: ads, emails, landing page sections
- Data analysis: interpret Triple Whale/Meta exports
- Script execution: any bash/Python task on the Mac Mini
- Voice note transcription (Whisper) → immediate action
- Notion read/write via API
- Gmail read/send via gog
- Calendar management via gog
- Alert routing: 🔴 Urgent → immediate | 🟡 High → hourly | 🟢 Medium → 3h batch

**CANNOT DO:**
- Build full landing pages from scratch (no front-end rendering)
- Run ads autonomously (no Meta/AppLovin API write access yet)
- Create visual designs
- Process video/image content natively

**ACTIVATION STATUS: ✅ Live**

---

### 🤖 MANUS
**Role:** The deep work agent. Long-running research, document creation, visual outputs.

**CAN DO:**
- Build full landing pages (HTML/CSS output)
- Deep market research (competitor analysis, trend reports)
- Comprehensive document creation (visual, structured)
- Mind maps and frameworks
- Multi-step research tasks that take 10-30 minutes
- Connect to Gmail, Notion, Google Calendar via connectors
- Output HTML, Markdown, PDF

**CANNOT DO:**
- Real-time responses (takes minutes, not seconds)
- Run scripts on your Mac
- Persistent memory between tasks (use project instructions)
- Manage cron jobs or automations

**ACTIVATION STATUS: ✅ Live | Project: The Singularity Epoche**
**ACTION:** Always include `project_id: dg4BCvqPq3wj5wSPxfjvRC` when creating tasks

---

### 🛒 SHOPIFY
**Role:** The storefront. Product, pricing, orders, customer data.

**CAN DO:**
- Product management, pricing updates
- Order/customer data export
- Discount codes, bundles
- Storefront customization (Liquid themes)
- Webhooks for order events

**CANNOT DO:**
- Analyze ad performance
- Write copy automatically
- Connect to ad platforms directly

**ACTIVATION STATUS: ✅ Live**
**KNOWN BUG:** BUY 2 GET 1 FREE pricing shows $45.99 (should be cheaper than $44.99 BUY 1). Fix needed.
**ACTION TASK:** Fix InnerFresh pricing bundle logic in Shopify admin.

---

### 📊 TRIPLE WHALE
**Role:** The analytics brain. Single source of truth for ecom performance.

**CAN DO:**
- Platform ROAS (with day-over-day % change)
- Spend tracking across Meta, Google, AppLovin
- Creative-level performance (CPA, ROAS per ad)
- Attribution modeling
- Cohort analysis, LTV tracking

**CANNOT DO:**
- Make bid adjustments automatically
- Write ad copy
- Create campaigns

**ACTIVATION STATUS: ✅ Live (manual review)**
**ACTION TASK:** Connect Triple Whale API to Clawd for automated daily performance pull → morning briefing.

---

### 📱 META ADS MANAGER
**Role:** Facebook + Instagram campaigns. Largest spend channel.

**CAN DO:**
- Campaign creation, ad sets, creatives
- Audience targeting, lookalikes, retargeting
- Creative testing (A/B)
- Performance data via API

**SCALING RULES (via Clawd):**
- CPA $60+ over 7 days → recommend turn off
- CPA <$30 with 3+ conversions over 7 days → recommend scale

**ACTIVATION STATUS: ✅ Live (manual execution)**
**ACTION TASK:** Connect Meta Ads API read access to Clawd for automated creative performance alerts.

---

### 📲 APPLOVIN
**Role:** Mobile ad network. Alternative to Meta for scale.

**CAN DO:**
- Mobile-first ad placements
- Performance data via API
- CPM/CTR tracking

**ACTIVATION STATUS: ✅ Live (manual review)**
**ACTION TASK:** Add AppLovin to daily performance pull.

---

### 🔍 GOOGLE ADS
**Role:** Search + display. Intent-based traffic.

**CAN DO:**
- Search campaigns, shopping ads
- Display retargeting
- Performance Max campaigns
- Keyword + audience data

**ACTIVATION STATUS: ✅ Live (manual review)**
**ACTION TASK:** Add Google Ads to daily performance pull.

---

### ✉️ GOG (Gmail + Google Calendar)
**Role:** Email and calendar automation layer.

**CAN DO:**
- Read/send Gmail programmatically
- Calendar event fetch/create
- Morning briefing data source
- Email categorization and summaries

**ACTIVATION STATUS: ✅ Live | Scopes: gmail + calendar authorized**
**KNOWN ISSUE:** Keychain "Allow all applications" must be enabled for gogcli for background cron access.
**ACTION TASK:** Verify Keychain setting for gogcli entry.

---

### 📋 CLICKUP
**Role:** Project management. Tasks, campaigns, creative briefs.

**CAN DO:**
- Task/project tracking
- Creative brief management
- Campaign status tracking
- API for task creation/updates

**ACTIVATION STATUS: ✅ Live (manual)**
**ACTION TASK:** Connect ClickUp API to Clawd for task creation from voice notes/commands.

---

### 📓 NOTION
**Role:** Knowledge base + Savage Advertising System.

**CAN DO:**
- Store performance insights, creative learnings, angle research
- Savage Advertising System structure
- Clawd can read/write via API
- Database views for campaigns, creatives, angles

**ACTIVATION STATUS: ✅ Live | API connected**
**ACTION TASK:** Build the performance intelligence database structure (see Section 3).

---

### 🎨 FIGMA
**Role:** Brand design files + creative assets.

**CAN DO:**
- Store brand guidelines, components, colors
- Export assets for ads
- Design system reference

**ACTIVATION STATUS: ✅ Connected (read-only)**
**Token stored:** `~/.config/figma/token`
**File:** `puWVN9ELEYg16gFHezJVUE` (Singularity Epoche canvas)

---

## 2. DECISION FRAMEWORK

| I want to... | Use this tool | Output |
|---|---|---|
| Write ad copy | Clawd | Draft in Telegram/Notion |
| Write email sequence | Clawd | Draft text |
| Build a landing page | Manus | HTML/deployed page |
| Analyze yesterday's ad performance | Clawd + Triple Whale | Daily report |
| Research competitor angle | Manus | Research document |
| Scale a winning creative | Clawd recommendation → Manual Meta | Campaign adjustment |
| Turn off underperforming ad | Clawd recommendation → Manual Meta | Campaign change |
| Create a ClickUp task | Clawd voice note → ClickUp API | Task created |
| Morning briefing | Clawd cron 7am | Calendar + inbox + todos |
| Deep creative analysis (7-day) | Clawd + Triple Whale data | Performance brief |
| Build a funnel strategy | Manus | Strategy document |
| Post brand insight to group | Clawd heartbeat → Telegram | Channel post |
| Transcribe voice note | Clawd + Whisper | Text action |
| Sync files/scripts | Clawd git-sync cron | Git push |

---

## 3. PERFORMANCE INTELLIGENCE LAYER

### What Gets Tracked
```
Ad Angles        → Which message/hook is converting
Creatives        → Which video/image/format is winning
Landing Pages    → Which variant is converting at what rate
Audiences        → Which segments are profitable
Offers           → Which bundle/price point converts best
```

### Where It Lives
```
Raw Data         → Triple Whale + Meta + AppLovin + Google
Daily Analysis   → Clawd morning briefing + ad performance report
Learnings Store  → Notion (Savage Advertising System)
Memory Layer     → Clawd memory files (daily notes + MEMORY.md)
```

### The Learning Loop
```
1. Platform data → Clawd pulls via API
2. Clawd analysis → identifies winners/losers
3. Recommendation → sent to Telegram (with action: scale/kill/test)
4. Decision made → Benni executes in platform
5. Result stored → Notion learning database
6. Next cycle → Clawd references past learnings when drafting copy/strategy
```

### Notion Database to Build
**Table: Creative Performance Log**
- Creative name/ID
- Platform (Meta/AppLovin/Google)
- Angle (hook category)
- CPA (7-day)
- ROAS (7-day)
- Spend
- Status (Active/Paused/Scaled)
- Key learnings (text)
- Date added

**Table: Angle Library**
- Angle name
- Core message
- Target emotion
- Best performing creative
- Conversion rate
- Status (Testing/Winner/Dead)

---

## 4. ACTION TASKS (PRIORITY ORDER)

### 🔴 This Week
1. **Fix Keychain for gog** — Enable "Allow all applications" for gogcli in Keychain Access → unlocks background Gmail in cron
2. **Fix InnerFresh BUY 2 GET 1 FREE pricing** — $45.99 → should be ~$43-44 range
3. **Build Notion Creative Performance Log** — database structure above
4. **Connect Triple Whale API to Clawd** — automate daily performance pull

### 🟡 Next Week
5. **Connect Meta Ads API (read)** — enable creative performance alerts in Clawd
6. **Build AppLovin + Google daily pull** — add to morning briefing or separate report
7. **ClickUp API integration** — voice note → task creation
8. **Mailer Profit contract review** — 36-month non-compete is too long, needs negotiation

### 🟢 This Month
9. **Build InnerFresh landing page v2** — Manus builds, Clawd briefs
10. **Figma brand system** — document InnerFresh brand colors, fonts, components in the Figma file
11. **Whisper → ClickUp pipeline** — voice note automatically creates ClickUp task
12. **Weekly creative debrief cron** — automated Clawd analysis every Sunday

---

## 5. THE OPERATING RHYTHM

```
DAILY (automated)
├── 7:00am  Morning briefing (calendar + inbox + todos)
├── 7:30am  Ad performance report (when platform APIs connected)
├── Every 30min  Heartbeat (email check, calendar alerts, git sync)
└── On demand  Voice note → instant action

WEEKLY (automated)
├── Sunday   Weekly memory synthesis
├── Monday   Security audit
└── Thursday  Creative performance review (when built)

ON DEMAND
├── "Write copy for [product/angle]" → Clawd
├── "Research [competitor/trend]" → Manus task
├── "Build landing page for [offer]" → Manus task
└── "What's working in ads this week" → Clawd + Triple Whale
```

---

## 6. MAILER PROFIT RETAINER

- **Contract:** $10,000/month, 12 months from 2026-03-05
- **Non-compete:** 36 months — flagged as too long
- **Action:** Review contract terms, negotiate non-compete down to 12 months

---

*This document lives at: `~/.openclaw/workspace/singularity-epoche.md`*
*Manus version (visual): https://manus.im/app/4B53NPH2mShpLYfYGPo4Vj*
