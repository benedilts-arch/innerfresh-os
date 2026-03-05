#!/usr/bin/env python3
"""Parse gateway log from stdin, print ERROR-level entries from the last hour."""
import sys, json
from datetime import datetime, timezone, timedelta

cutoff = datetime.now(timezone.utc) - timedelta(hours=1)
errors = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        if d.get('_meta', {}).get('logLevelName') != 'ERROR':
            continue
        ts_str = d.get('time', '')
        if ts_str:
            ts = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
            if ts < cutoff:
                continue
        msg = str(d.get('0', ''))[:120]
        errors.append(msg)
    except:
        if line.upper().startswith('ERROR') or 'FATAL' in line.upper():
            errors.append(line[:120])

for e in errors[-3:]:
    print(e)
