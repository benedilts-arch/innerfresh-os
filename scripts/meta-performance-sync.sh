#!/bin/bash
# Meta Ads Performance Sync — weekly creative intelligence update
# Pulls all ad performance + creative data and saves to workspace

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE="$(dirname "$SCRIPT_DIR")"
LOG_DB="$WORKSPACE/data/cron.db"
JOB_NAME="meta-performance-sync"

log_start() {
  python3 -c "
import sqlite3, time
conn = sqlite3.connect('$LOG_DB')
conn.execute('CREATE TABLE IF NOT EXISTS cron_log (id INTEGER PRIMARY KEY, job TEXT, status TEXT, message TEXT, ts INTEGER)')
conn.execute('INSERT INTO cron_log (job, status, message, ts) VALUES (?, ?, ?, ?)', ('$JOB_NAME', 'started', 'sync started', int(time.time())))
conn.commit(); conn.close()
" 2>/dev/null || true
}

TOKEN=$(cat ~/.config/meta/access_token 2>/dev/null || echo "")
ACCOUNT="act_364231677921804"

if [ -z "$TOKEN" ]; then
  echo "ERROR: No Meta access token found at ~/.config/meta/access_token"
  exit 1
fi

mkdir -p "$WORKSPACE/data/creatives/thumbnails"

python3 << PYEOF
import json, urllib.request, re, subprocess, os, time

TOKEN = open(os.path.expanduser('~/.config/meta/access_token')).read().strip()
ACCOUNT = "act_364231677921804"
WORKSPACE = "$WORKSPACE"

print(f"[{time.strftime('%Y-%m-%d %H:%M')}] Starting Meta performance sync...")

# Pull ad performance (last 7 days)
r = subprocess.run(['curl', '-s', f'https://graph.facebook.com/v19.0/{ACCOUNT}/insights?fields=ad_id,ad_name,adset_name,spend,impressions,cpm,ctr,cpc,actions,cost_per_action_type&date_preset=last_7d&level=ad&limit=100&access_token={TOKEN}'], capture_output=True)
perf_data = json.loads(r.stdout.decode('utf-8', errors='replace'))
ads_perf = perf_data.get('data', [])
print(f"Got {len(ads_perf)} ads with performance data")

# Pull creative IDs
r2 = subprocess.run(['curl', '-s', f'https://graph.facebook.com/v19.0/{ACCOUNT}/ads?fields=id,name,creative&limit=100&access_token={TOKEN}'], capture_output=True)
ads_data = json.loads(r2.stdout.decode('utf-8', errors='replace'))
ad_to_creative = {a['id']: a.get('creative', {}).get('id', '') for a in ads_data.get('data', [])}

# Pull & cache creative details
creative_cache_path = f"{WORKSPACE}/data/creatives/creative_db.json"
if os.path.exists(creative_cache_path):
    with open(creative_cache_path) as f:
        existing = {c['id']: c for c in json.load(f)}
else:
    existing = {}

new_ids = set(cid for cid in ad_to_creative.values() if cid and cid not in existing)
print(f"Fetching {len(new_ids)} new creatives...")

for cid in list(new_ids)[:50]:
    r = subprocess.run(['curl', '-s', f'https://graph.facebook.com/v19.0/{cid}?fields=id,title,body,thumbnail_url,image_url&access_token={TOKEN}'], capture_output=True)
    try:
        c = json.loads(r.stdout.decode('utf-8', errors='replace'))
    except:
        continue
    thumb_url = c.get('thumbnail_url') or c.get('image_url')
    thumb_path = None
    if thumb_url:
        safe = re.sub(r'[^a-zA-Z0-9_-]', '_', (c.get('title') or cid)[:40])
        path = f"{WORKSPACE}/data/creatives/thumbnails/{safe}.jpg"
        try:
            urllib.request.urlretrieve(thumb_url, path)
            thumb_path = path
        except:
            pass
    existing[cid] = {'id': cid, 'title': c.get('title',''), 'body_preview': c.get('body','')[:200], 'thumb': thumb_path}

with open(creative_cache_path, 'w') as f:
    json.dump(list(existing.values()), f, indent=2, ensure_ascii=False)

# Build master performance DB
master = []
for p in ads_perf:
    ad_id = p.get('ad_id', '')
    creative_id = ad_to_creative.get(ad_id, '')
    creative = existing.get(creative_id, {})
    purchases = 0
    cpa = 0.0
    for action in p.get('actions', []):
        if 'purchase' in action.get('action_type', ''):
            purchases = int(float(action.get('value', 0)))
    for cp in p.get('cost_per_action_type', []):
        if 'purchase' in cp.get('action_type', ''):
            cpa = float(cp.get('value', 0))
    spend = float(p.get('spend', 0))
    if cpa == 0 and purchases > 0:
        cpa = spend / purchases
    master.append({
        'ad_id': ad_id, 'ad_name': p.get('ad_name',''), 'adset_name': p.get('adset_name',''),
        'creative_id': creative_id, 'creative_title': creative.get('title',''),
        'creative_preview': creative.get('body_preview',''), 'thumb_path': creative.get('thumb',''),
        'spend': round(spend,2), 'cpa': round(cpa,2), 'purchases': purchases,
        'cpm': round(float(p.get('cpm',0)),2), 'ctr': round(float(p.get('ctr',0)),2),
        'cpc': round(float(p.get('cpc',0)),2), 'impressions': int(p.get('impressions',0)),
        'sync_date': time.strftime('%Y-%m-%d')
    })

master.sort(key=lambda x: x['spend'], reverse=True)
with open(f"{WORKSPACE}/data/creatives/master_performance.json", 'w') as f:
    json.dump(master, f, indent=2, ensure_ascii=False)

total_spend = sum(m['spend'] for m in master)
total_sales = sum(m['purchases'] for m in master)
avg_cpa = total_spend / total_sales if total_sales else 0
print(f"Sync complete: {len(master)} ads | \${total_spend:.2f} spend | {total_sales} sales | CPA \${avg_cpa:.2f}")
PYEOF
