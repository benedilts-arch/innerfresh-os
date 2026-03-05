#!/usr/bin/env python3
"""
Withings connector — weight, body composition (fat%, muscle, bone, water).
Normalizes to: {timestamp, source, metric, value, unit}

Withings measure types:
  1=weight(kg), 5=fat_free_mass(kg), 6=fat_ratio(%), 8=fat_mass_weight(kg),
  76=muscle_mass(kg), 77=hydration(kg), 88=bone_mass(kg)
"""

import os, sys, json, subprocess, urllib.request, urllib.parse
from datetime import datetime, timedelta, timezone
from pathlib import Path

MEASURE_TYPES = {
    1:  ("weight", "kg"),
    5:  ("fat_free_mass", "kg"),
    6:  ("body_fat", "percent"),
    8:  ("fat_mass", "kg"),
    76: ("muscle_mass", "kg"),
    77: ("hydration", "kg"),
    88: ("bone_mass", "kg"),
}

def load_config():
    result = subprocess.run(
        ["bash", "-c", "source ~/.config/health/config.sh 2>/dev/null && echo WITHINGS_ACCESS_TOKEN=$WITHINGS_ACCESS_TOKEN && echo WITHINGS_USER_ID=$WITHINGS_USER_ID"],
        capture_output=True, text=True
    )
    cfg = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            cfg[k.strip()] = v.strip()
    return cfg

def fetch_measurements(token: str, startdate: int, enddate: int) -> list:
    meastypes = ",".join(str(k) for k in MEASURE_TYPES)
    payload = urllib.parse.urlencode({
        "action": "getmeas",
        "meastypes": meastypes,
        "category": 1,
        "startdate": startdate,
        "enddate": enddate,
    }).encode()

    req = urllib.request.Request(
        "https://wbsapi.withings.net/measure",
        data=payload,
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/x-www-form-urlencoded"},
        method="POST"
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read()).get("body", {}).get("measuregrps", [])
    except Exception as e:
        print(f"[withings] fetch error: {e}", file=sys.stderr)
        return []

def normalize(groups: list) -> list:
    out = []
    for grp in groups:
        ts = datetime.fromtimestamp(grp.get("date", 0), tz=timezone.utc).isoformat()
        for measure in grp.get("measures", []):
            mtype = measure.get("type")
            if mtype not in MEASURE_TYPES:
                continue
            metric, unit = MEASURE_TYPES[mtype]
            # Withings stores value as integer × 10^unit
            raw = measure.get("value", 0)
            exp = measure.get("unit", 0)
            value = round(raw * (10 ** exp), 4)
            out.append({"timestamp": ts, "source": "withings", "metric": metric, "value": value, "unit": unit})
    return out

def run(days: int = 30) -> list:
    cfg = load_config()
    token = cfg.get("WITHINGS_ACCESS_TOKEN", os.environ.get("WITHINGS_ACCESS_TOKEN", ""))
    if not token:
        print("[withings] No token configured.", file=sys.stderr)
        return []

    now = int(datetime.now(timezone.utc).timestamp())
    start = int((datetime.now(timezone.utc) - timedelta(days=days)).timestamp())
    groups = fetch_measurements(token, start, now)
    records = normalize(groups)
    print(f"[withings] {len(records)} measurements from {len(groups)} weigh-ins", file=sys.stderr)
    return records

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=30)
    parser.add_argument("--output", default="-")
    args = parser.parse_args()

    records = run(args.days)
    out = open(args.output, "a") if args.output != "-" else sys.stdout
    for r in records:
        out.write(json.dumps(r) + "\n")
    if args.output != "-":
        out.close()
    print(f"[withings] wrote {len(records)} metrics", file=sys.stderr)
