# InnerFresh Operating System Specification
**Mind Map for Figma Board — Complete Blueprint**

---

## 1. CENTRAL NODE: InnerFresh Operating System

**Core concept:** Single integrated platform managing all aspects of InnerFresh brand, operations, and growth.

**Color:** Brand primary (TBD from Singularity Epoche)

---

## 2. SIX MAIN PILLARS (radiating from center)

### PILLAR 1: Pages & Angles Dashboard
**Purpose:** Track performance by Facebook page and angle combination

**Components:**
- List of 5 Native Pages:
  - Dr. Lisa Jones (Medical Authority)
  - Dr. Rachel Thompson (Medical Authority)
  - Women's Health Insider (Community/Editorial)
  - Every Women's Health (Community/Editorial)
  - Women's Wellbeing (Community/Editorial)

- For each page, show:
  - ✅ **Live** (advertorial running, CPA, ROAS, status)
  - 🧪 **Testing** (new angle, gather data)
  - 🚫 **Paused** (kill criteria met)
  - 💡 **Recommendations** (next angle to test, brand-aligned)

**Data shown per ad:**
- Ad ID | Advertorial Type | Angle | Copy Hook | Creative Visual | Spend (7d) | CPA | ROAS | Conversions | Status

**AI Sidenotes - My Role:**
- 🤖 **Hook Optimization:** "Test 5 variations of this hook on this angle"
- 🤖 **Angle Gaps:** "Weight Gain untested on authority pages → recommend test"
- 🤖 **Brand Compliance:** "This creative off-brand for Dr. page → flag"
- 🤖 **Copy Iteration:** "Winner CPA <$25 → generate 3 copy variations"
- 🤖 **Page Recommendations:** "This angle performs 2x on community pages → test there"

**Data Source:** Meta Ads API (daily) + Creative Intelligence Sheet

---

### PILLAR 2: Creative Intelligence Dashboard
**Purpose:** Real-time performance tracking + winner flagging + recommendations

**Components:**
- **Performance Matrix:**
  - Ad ID | Creative | Advertorial | Page | Angle | Spend | CPA | ROAS | Impressions | CTR | Status
  - Sort by: Top performers, recent adds, failures

- **Tag System (color-coded):**
  - 🟢 **Performing** (CPA <$30, 3+ conversions, 7d)
  - 🟡 **Testing** (gathering data, <5 conversions)
  - 🔴 **Failing** (CPA >$60, low ROAS)
  - 🎯 **Brand-Aligned** (matches Singularity Epoche)
  - ⚠️ **Off-Brand** (doesn't fit page/angle combo)

- **Smart Recommendations (right panel):**
  - "AVATAR #3 at $18 CPA → scale to 3 untested pages"
  - "This angle untested on authority page → test here"
  - "Creative-advertorial mismatch → pause this combo"
  - "Email sequence performing 2% → improve copy for retention"

**Columns Tracked:**
- Ad ID (Meta tracking)
- Post ID (Figma link to creative)
- Advertorial paired
- Landing page URL
- Audience targeted
- Spend last 7d
- Conversions last 7d
- CPA / ROAS
- Impressions / CTR
- Created date
- Last updated
- Status (live/testing/paused)
- Next action

**AI Sidenotes - My Role:**
- 🤖 **Daily Performance Review:** "Identify top 3 winners, bottom 3 losers"
- 🤖 **Winner Iteration:** "High performer → brief copywriter for 5 variations"
- 🤖 **Failure Analysis:** "Why did this fail? Off-brand? Wrong audience? Wrong hook?"
- 🤖 **Cross-Page Testing:** "This worked here → test on these 3 pages"
- 🤖 **Email Follow-up:** "Store high-performer IDs → generate nurture sequence"
- 🤖 **Tag Automation:** "CPA <$30 → auto-tag green, brief for scale"

**Data Source:** Meta Ads API (real-time) + Shopify conversions (daily)

---

### PILLAR 3: Meta Winners Hub
**Purpose:** Isolate top performers, flag for scaling/iteration

**Components:**
- **Today's Top Performers (live, refreshes daily 7am):**
  - Rank | Creative | CPA | ROAS | Spend | Page | Angle | Recommendation

- **This Week's Winners (7d aggregate):**
  - Top 10 by CPA
  - Top 10 by ROAS
  - Highest spend efficiency

- **Action Queue:**
  - 🚀 **Ready to Scale** (3+ conversions, CPA <$25)
  - 🧪 **Worth Testing More** (CPA <$35, low spend, high potential)
  - 💡 **Copy Variation** (high performer, ready for hook/angle test)
  - 📧 **Email Integration** (high ROAS, use for nurture)

**Display Format:**
- Creative thumbnail | Ad copy preview | Page | Angle | CPA | ROAS | Status | Next Action

**AI Sidenotes - My Role:**
- 🤖 **Daily Briefing:** "Your winners from yesterday + recommended actions"
- 🤖 **Scaling Strategy:** "This angle at $18 CPA → scale to these 4 untested pages"
- 🤖 **Creative Fatigue:** "This creative paused after 20 days → generate replacement"
- 🤖 **Angle Expansion:** "Doctor angle working → test on community pages too"
- 🤖 **Email Handoff:** "High performer → auto-trigger email sequence brief"

**Data Source:** Meta Ads API (real-time, 7d rolling)

---

### PILLAR 4: Brand Intelligence (The Operating System)
**Purpose:** Map entire business structure, ownership, dependencies, automation opportunities

**Sub-sections:**

#### 4A: OWNERSHIP & ORG CHART
```
InnerFresh Operating System
├── Benni (Strategy, Copy, Brand Decisions, Platform Ops)
│   ├── Owns: Ad strategy, copy direction, brand alignment
│   ├── Approves: All creatives, advertorials, launches
│   └── Reports to: Jan (CEO)
│
├── Jan Gassmann (CEO)
│   ├── Owns: Business decisions, partnerships, growth strategy
│   └── Reports to: (Board/Investors if applicable)
│
├── Designer (FT)
│   ├── Owns: Visual assets, Figma, creative briefs execution
│   ├── Waits on: Copywriter (brief), Benni (approval)
│   └── Supports: Video Editor (asset creation)
│
├── Copywriter (FT)
│   ├── Owns: Advertorials, copy variations, email copy, hooks
│   ├── Waits on: Benni (strategy/decision), Creative Intelligence (winner flagging)
│   └── Briefs: Designer (visual execution)
│
├── Video Editor (FT)
│   ├── Owns: UGC scripts, video production, asset library
│   ├── Waits on: Copywriter (copy/scripts)
│   └── Uses: Designer assets
│
├── Support (FT)
│   ├── Owns: Customer emails, refund handling, support tickets
│   └── Inputs: Copywriter (email templates)
│
└── Zarak (Email Contractor)
    ├── Owns: Email campaign setup, email sequences, segmentation
    ├── Waits on: Copywriter (copy), Creative Intelligence (performance data)
    └── Updates: Benni (performance)
```

#### 4B: DEPENDENCIES & WAIT CHAINS
```
COPY ITERATION LOOP:
Creative Intelligence (flag winner)
  ↓ (Benni sees winner)
Benni (approve iteration)
  ↓ (brief copywriter)
Copywriter (write 5 copy variations + new hooks)
  ↓ (deliver to designer + Benni)
Benni (brand check)
  ↓ (approve)
Designer (create new visuals)
  ↓ (export assets)
Copywriter (pair copy + creative)
  ↓ (ready to launch)
Benni (final approval)
  ↓ (launch to page)
Meta (ad live)
  ↓ (track performance)
Creative Intelligence (updated daily)

LAUNCH WORKFLOW:
Decision (new angle to test)
  ↓
Benni (strategy brief)
  ↓
Copywriter (write advertorial)
  ↓ (deliver brief)
Designer (create assets)
  ↓ (approve)
Benni (brand alignment check)
  ↓ (final brief)
Video Editor (UGC script if video)
  ↓
Zarak (email sequence if needed)
  ↓ (launch day)
Benni (approval)
  ↓
Live on page(s)

EMAIL FOLLOW-UP:
Creative Intelligence (high ROAS ad)
  ↓ (brief for email)
Copywriter (write email sequence)
  ↓
Designer (email template)
  ↓
Zarak (set up in email platform)
  ↓
Live in campaign
  ↓
Support (handle replies)
```

#### 4C: AUTOMATION OPPORTUNITIES
**Where I can eliminate wait time:**

- ✅ **Copy Iteration Automation**
  - System flags winner → auto-brief copywriter with 5 hook variations
  - Copywriter writes advertorial → I generate 3 email sequences
  - High performer selected → auto-generate SMS version

- ✅ **Design Recommendations**
  - Winning copy + angle → suggest design visual themes
  - Copywriter complete → auto-generate Figma brief for designer

- ✅ **Approval Workflow**
  - Copy submitted → brand compliance check (vs. Singularity Epoche)
  - Creative submitted → brand alignment score + approval recommendation
  - Launch ready → auto-check page-advertorial logic (authority vs. community)

- ✅ **Performance Analysis**
  - Daily: flag top 3 winners, bottom 3 killers
  - Weekly: angle performance summary, untested opportunities
  - Monthly: channel performance, LTV by angle, retention cohorts

- ✅ **Task Assignment**
  - Winner flagged → auto-task copywriter "Generate 5 variations"
  - Copy ready → auto-task designer "Create visual brief"
  - Launch approved → auto-task video editor "Create UGC script"

**AI Sidenotes - My Role:**
- 🤖 **Daily Ops Briefing:** Who waits on whom, what's blocked, what's ready to ship
- 🤖 **Workload Balancing:** "Designer has 3 briefs pending, copywriter free → prioritize video"
- 🤖 **Risk Flagging:** "Designer overloaded, video editor waiting → reduce scope"
- 🤖 **Handoff Automation:** Format briefs, assign tasks, set deadlines

---

### PILLAR 5: Content Factory
**Purpose:** Systemize content creation across channels from proven angles

**Components:**

#### 5A: CORE OUTPUT TYPES
**From each winning angle/copy:**

1. **Advertorials** (1200-1800 words)
   - Long-form for native networks
   - Tested on 11 URLs

2. **UGC Scripts** (15-60 sec)
   - TikTok, Reels, YouTube Shorts
   - 3-5 variations per angle

3. **Email Sequences** (5-email nurture)
   - Onboarding after ad click
   - Product education
   - Cart recovery

4. **VSL Scripts** (60-120 sec)
   - Sales page video scripts
   - Emotional hook + proof + CTA

5. **SMS Sequences** (3-5 texts)
   - Urgency/scarcity
   - Retention
   - Win-back

6. **Blog Posts** (2000+ words)
   - SEO play on angles
   - Long-tail keywords
   - Builds authority

7. **Affiliate Assets** (swipe copy + graphics)
   - Partner email copy
   - Social copy
   - Landing page variants

#### 5B: CONTENT CALENDAR
- **Input:** Winning angle + performance data
- **Output:** 30-day content calendar (what launches where, when)
- **Ownership:** Benni (approves), Copywriter (writes), Designer (visuals), Video Editor (UGC)
- **Status:** Planned → Approved → In Production → Shipped → Tracking

#### 5C: QUALITY GATES
- All content must align to Singularity Epoche
- All angles tested via Meta first (proof of concept)
- All copy humanized (vs AI-written detection)
- All UGC branded (not generic)

**AI Sidenotes - My Role:**
- 🤖 **Angle → Content:** "This angle won → generate advertorial, 3 email sequences, 5 UGC scripts"
- 🤖 **Multi-Format:** "One core message → 7 formats (ad copy, email, UGC, VSL, SMS, blog, affiliate)"
- 🤖 **Brand Enforcement:** Every output checked against Singularity Epoche
- 🤖 **Production Brief:** Auto-generate briefs for copywriter, designer, video editor
- 🤖 **Calendar Management:** "Here's your 30-day content pipeline by channel"

**Data Source:** Creative Intelligence (winners) + performance metrics

---

### PILLAR 6: Distribution & Growth Channels
**Purpose:** Expand beyond Meta to other platforms while maintaining brand alignment

**Components:**

#### 6A: PAID CHANNELS
- **Meta (Facebook/Instagram)** — primary channel, 131 copies, 11 URLs
- **Google Ads** — same angles, different audiences (keyword targeting)
- **TikTok Ads** — UGC-style creatives, younger demographic
- **Amazon DSP** — supplement + upsell to existing customers
- **Affiliate Networks** — partner-driven traffic, commission-based
- **Native Networks** (Taboola, Outbrain) — advertorials as content

**For each channel:**
- Best performing angles (from Meta learnings)
- Recommended budget allocation
- Creative format requirements
- Expected ROAS (based on historical)
- Status (testing/scaling/optimized)

#### 6B: OWNED CHANNELS
- **Email (Zarak)** — triggered sequences, win-back, retention
- **SMS** — urgency, refund reminders, upsells
- **Organic Social** — content repurposing from UGC library
- **Blog** — SEO + authority building

#### 6C: RETAIL & CHECKOUT OPTIONS
- **Shopify (primary)**
  - Standard checkout
  - One-click upsells
  - Post-purchase email sequences

- **Checkout Champ**
  - Fast, minimal form checkout
  - Recommended for high-traffic ads

- **Amazon (if expanding)**
  - Product listing optimization
  - Sponsored ads
  - Enhanced brand content

- **TikTok Shop** (future)
  - Shoppable TikToks
  - Creator integration
  - Lower friction

- **Affiliate Network**
  - Partner payouts
  - Commission tracking
  - Brand control guidelines

**AI Sidenotes - My Role:**
- 🤖 **Channel Expansion:** "This angle won on Meta → recommend test on Google Ads, TikTok, affiliate"
- 🤖 **Format Adaptation:** "Advertorial winning → adapt for native networks, email, SMS"
- 🤖 **Budget Allocation:** "Meta ROAS 2.5x → recommend 40% budget. Google 1.2x → 25% budget"
- 🤖 **Affiliate Briefs:** Auto-generate affiliate email copy, social copy, landing variants
- 🤖 **Checkout Optimization:** "Conversion rate 2.1% → test Checkout Champ, expected +0.3%"

**Data Source:** Meta (primary) + Triple Whale (multi-channel ROAS) + Shopify (conversion funnel)

---

## 3. DATA FLOWS & INTEGRATION LAYER

### INPUT DATA SOURCES:
```
Figma (design tasks, brand guidelines, asset library)
  ↓
Google Sheets (Creative Intelligence — 131 copies, 11 URLs, performance)
  ↓
Meta Ads API (daily: spend, conversions, CPA, ROAS by ad)
  ↓
Shopify API (customer LTV, retention, AOV, refunds, cohorts)
  ↓
Triple Whale (multi-channel ROAS aggregation)
  ↓
Google Ads API (optional, when live)
  ↓
Manus API (dispatch creative iteration tasks, advertorial generation)
  ↓
Database (InnerFresh Operating System)
```

### OUTPUT DASHBOARDS:
```
Creative Intelligence Dashboard (real-time, updated daily 7am)
  ↓
Meta Winners Hub (daily flagging of top performers)
  ↓
Pages & Angles Dashboard (updated daily, recommendations)
  ↓
Brand Intelligence (Org + ownership view, weekly refresh)
  ↓
Content Factory Calendar (30-day pipeline)
  ↓
Daily Briefing to Benni (7am Dubai: winners, action items, anomalies)
  ↓
Weekly Strategic Review (performance by angle, LTV by channel, untested opportunities)
```

---

## 4. SINGULARITY EPOCHE INTEGRATION

**Where it lives:** Center of Brand Intelligence pillar

**What it enforces:**
- ✅ All creatives must match brand visual identity
- ✅ All copy must match brand voice (empathetic, not clinical, no bro-science)
- ✅ All angles must fit hero angle: "Gaining weight on 900 calories?"
- ✅ Medical pages get medical angles (Doctor, TSH, Hypothyroid)
- ✅ Community pages get emotional angles (Weight Gain, Broken Keys, 5 Reasons)
- ✅ No angle tested until brand-aligned

**AI Role:** Automatically check every asset against Singularity Epoche before approval

---

## 5. DESIGN SYSTEM (for Figma Board)

### Color Scheme:
- **Primary (Brand):** InnerFresh brand color (TBD)
- **Performing (Green):** #10B981
- **Testing (Yellow):** #F59E0B
- **Failing (Red):** #EF4444
- **Brand-Aligned (Blue):** #3B82F6
- **Off-Brand (Orange):** #FF8C42

### Typography:
- **Headings:** Bold, clear hierarchy
- **Data:** Monospace for numbers (CPA, ROAS)
- **Labels:** Small caps for categories

### Layout Principles:
- Radial mind map from center (InnerFresh Operating System)
- 6 pillars radiating out
- Sub-nodes branch from each pillar
- Dependency arrows show wait chains
- AI sidenotes in smaller font, italicized

---

## 6. FIGMA BOARD STRUCTURE (for Designer)

### Frame Layout:
```
Main Board (4000x3000px):
├── Center: "InnerFresh Operating System" node (color: brand)
├── Pillar 1 - Pages & Angles (upper right, 800x600)
├── Pillar 2 - Creative Intelligence (middle right, 900x700)
├── Pillar 3 - Meta Winners (lower right, 700x600)
├── Pillar 4 - Brand Intelligence (lower left, 1000x800)
│   ├── 4A: Org Chart (300x400)
│   ├── 4B: Dependency Flows (400x400)
│   └── 4C: Automation (300x400)
├── Pillar 5 - Content Factory (upper left, 900x600)
└── Pillar 6 - Distribution & Checkout (lower, 1200x500)

Separate Detailed Frames:
├── "Pages & Angles Detail" (2000x1200)
├── "Creative Intelligence Detail" (2200x1400)
├── "Org Chart Detail" (1500x1000)
├── "Dependency Flows Detail" (1800x1200)
├── "Content Factory Pipeline" (2000x800)
└── "Channel Strategy" (2000x1000)
```

### Interactive Prototype:
- Click on pillar → zoom to detailed frame
- Click on role → see tasks/dependencies
- Click on winner → see recommendations
- Links between related concepts

---

## 7. IMPLEMENTATION CHECKLIST FOR DESIGNER

- [ ] Create main board with 6 pillars radiating from center
- [ ] Add color coding (performing green, testing yellow, failing red)
- [ ] Create org chart with roles + wait chains
- [ ] Add dependency flow arrows (who waits on whom)
- [ ] Create detailed frames for each pillar (clickable from main)
- [ ] Add AI sidenotes (italicized, smaller text) to each major component
- [ ] Create content factory pipeline (input → output types)
- [ ] Add channel strategy visual (paid + owned + retail)
- [ ] Link related concepts with arrows
- [ ] Create interactive prototype (click pillar → detail frame)
- [ ] Add legend (colors, symbols, data sources)
- [ ] Share with Benni for approval

**Estimated time:** 2-3 hours (experienced Figma designer)

---

## 8. NEXT STEPS AFTER FIGMA BOARD

1. **Designer builds board** (this week)
2. **Benni approves structure** (day 1 of next week)
3. **Spawn Codex agent** to build actual working platform (weeks 2-4)
   - Frontend: React dashboards (Pages & Angles, Creative Intelligence, Meta Winners)
   - Backend: Node.js APIs (Figma sync, Sheets sync, Meta API)
   - Database: PostgreSQL (campaigns, creatives, performance history)
   - Automation: Cron jobs (daily briefings, winner flagging, task assignment)

4. **Parallel:** Integrate with existing systems
   - Meta API (daily performance sync)
   - Shopify API (customer LTV, retention)
   - Google Sheets (Creative Intelligence live data)
   - Figma API (design task tracking)

5. **Launch:** InnerFresh Operating System live (fully operational, 3-4 weeks)

---

## KEY METRICS TO TRACK

- **Creative Performance:** CPA, ROAS, conversions by ad/angle/page
- **Channel Performance:** ROAS by channel (Meta, Google, TikTok, affiliate)
- **Business Health:** LTV by cohort, retention by angle, CAC by channel
- **Team Efficiency:** Time from brief → launch, creative iterations per winner
- **Brand Alignment:** % of launches that match Singularity Epoche guidelines
- **Growth:** New angles tested/month, new channels launched, revenue growth

---

**This spec is your master blueprint. Designer builds Figma → you approve → Codex builds the working system. 🦞**
