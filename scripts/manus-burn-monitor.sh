#!/bin/bash
# Manus Burn Rate Monitor — kills tasks burning >$0.50/min, alerts Benni
# Cron: every 1 minute

API_KEY=$(cat ~/.config/manus/api_key 2>/dev/null || echo "")
STATE_FILE="/Users/aiassistant/.openclaw/workspace/data/manus-burn-state.json"
THRESHOLD=7          # credits/min ≈ $0.50/min (based on $25/364 credits = $0.069/credit)
PROJECT="dg4BCvqPq3wj5wSPxfjvRC"
TELEGRAM_CHAT="6560403362"

[ -z "$API_KEY" ] && exit 0

python3 - << 'PYEOF'
import json, subprocess, time, os, sys

API_KEY     = open(os.path.expanduser("~/.config/manus/api_key")).read().strip()
STATE_FILE  = "/Users/aiassistant/.openclaw/workspace/data/manus-burn-state.json"
THRESHOLD   = 7        # credits/min
CPD         = 14.56    # credits per dollar
PROJECT     = "dg4BCvqPq3wj5wSPxfjvRC"

def api(path, method="GET"):
    args = ['curl', '-s']
    if method == "DELETE": args += ['-X', 'DELETE']
    args += [f'https://api.manus.ai/v1{path}', '-H', f'API_KEY: {API_KEY}']
    r = subprocess.run(args, capture_output=True)
    try: return json.loads(r.stdout.decode())
    except: return {}

def alert(msg):
    subprocess.run([
        'bash', '/Users/aiassistant/.openclaw/workspace/scripts/notify.sh',
        'critical', 'manus-burn-monitor', msg
    ], capture_output=True)

state = {}
if os.path.exists(STATE_FILE):
    try:
        with open(STATE_FILE) as f: state = json.load(f)
    except: pass

tasks_data = api(f'/tasks?project_id={PROJECT}')
running = [t for t in tasks_data.get('data', []) if t.get('status') == 'running']
now = int(time.time())
new_state = {}

for task in running:
    tid     = task['id']
    credits = task.get('credit_usage') or 0
    title   = task.get('metadata', {}).get('task_title', tid)[:50]

    prev          = state.get(tid, {})
    prev_credits  = prev.get('credits', credits)
    prev_ts       = prev.get('ts', now)
    elapsed_min   = (now - prev_ts) / 60.0

    rate = ((credits - prev_credits) / elapsed_min) if elapsed_min >= 0.5 else 0
    new_state[tid] = {'credits': credits, 'ts': now, 'rate': round(rate, 2)}

    if rate >= THRESHOLD:
        api(f'/tasks/{tid}', method='DELETE')
        msg = (
            f"🔴 Manus task KILLED — burn rate ${rate/CPD:.2f}/min exceeded $0.50 limit\n"
            f"Task: {title}\n"
            f"Credits burned: {credits} (~${credits/CPD:.2f} total)\n"
            f"Rate: {rate:.1f} credits/min"
        )
        alert(msg)
        print(f"KILLED {tid}: {rate:.1f} cr/min")
    else:
        print(f"OK {title[:30]}: {credits} credits | {rate:.1f} cr/min")

os.makedirs(os.path.dirname(STATE_FILE), exist_ok=True)
with open(STATE_FILE, 'w') as f:
    json.dump(new_state, f)

if not running:
    print("No running Manus tasks.")
PYEOF
