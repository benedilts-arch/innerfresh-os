#!/usr/bin/env python3
"""
Oura Ring connector — pulls sleep, HRV, readiness, activity.
Normalizes to: {timestamp, source, metric, value, unit}
"""

import os, sys, json, subprocess
from datetime import date, timedelta
from pathlib import Path

HEALTH_DIR = Path.home() / ".openclaw" / "workspace" / "health"
CONFIG_FILE = Path.home() / ".config" / "health" / "config.sh"

def load_config():
    if not CONFIG_FILE.exists():
        return {}
    result = subprocess.run(
        ["bash", "-c", f"source {CONFIG_FILE} && echo OURA_TOKEN=$OURA_TOKEN"],
        capture_output=True, text=True
    )
    cfg = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            cfg[k.strip()] = v.strip()
    return cfg

def fetch(endpoint: str, token: str, params: dict = {}) -> dict:
    import urllib.request, urllib.parse
    qs = urllib.parse.urlencode(params)
    url = f"https://api.ouraring.com/v2/usercollection/{endpoint}?{qs}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read())
    except Exception as e:
        print(f"[oura] fetch error {endpoint}: {e}", file=sys.stderr)
        return {}

def normalize(records: list) -> list:
    """Convert Oura API records to unified metric format."""
    out = []
    for r in records:
        day = r.get("day", r.get("date", ""))
        ts = f"{day}T00:00:00Z" if day else ""

        # Sleep
        if "total_sleep_duration" in r:
            for metric, unit in [
                ("total_sleep_duration", "seconds"),
                ("rem_sleep_duration", "seconds"),
                ("deep_sleep_duration", "seconds"),
                ("light_sleep_duration", "seconds"),
                ("awake_time", "seconds"),
                ("sleep_score", "score"),
                ("efficiency", "percent"),
                ("hr_lowest", "bpm"),
                ("average_hrv", "ms"),
            ]:
                if r.get(metric) is not None:
                    out.append({"timestamp": ts, "source": "oura", "metric": metric, "value": r[metric], "unit": unit})

        # Readiness
        if "score" in r and "contributors" in r:
            out.append({"timestamp": ts, "source": "oura", "metric": "readiness_score", "value": r["score"], "unit": "score"})
            for k, v in r.get("contributors", {}).items():
                if v is not None:
                    out.append({"timestamp": ts, "source": "oura", "metric": f"readiness_{k}", "value": v, "unit": "score"})

        # Activity
        if "steps" in r:
            for metric, unit in [("steps", "count"), ("active_calories", "kcal"), ("total_calories", "kcal"), ("met", "met")]:
                if r.get(metric) is not None:
                    out.append({"timestamp": ts, "source": "oura", "metric": metric, "value": r[metric], "unit": unit})

        # HRV
        if "night_rmssd" in r or "day_rmssd" in r:
            for metric in ["night_rmssd", "day_rmssd"]:
                if r.get(metric) is not None:
                    out.append({"timestamp": ts, "source": "oura", "metric": f"hrv_{metric}", "value": r[metric], "unit": "ms"})

    return out

def run(days: int = 7) -> list:
    cfg = load_config()
    token = cfg.get("OURA_TOKEN", os.environ.get("OURA_TOKEN", ""))
    if not token:
        print("[oura] No token configured. Set OURA_TOKEN in ~/.config/health/config.sh", file=sys.stderr)
        return []

    start = (date.today() - timedelta(days=days)).isoformat()
    end = date.today().isoformat()
    params = {"start_date": start, "end_date": end}

    all_records = []
    for endpoint in ["sleep", "readiness", "daily_activity", "heartrate"]:
        data = fetch(endpoint, token, params)
        records = data.get("data", [])
        all_records.extend(normalize(records))
        print(f"[oura] {endpoint}: {len(records)} records", file=sys.stderr)

    return all_records

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--output", default="-")
    args = parser.parse_args()

    records = run(args.days)
    out = open(args.output, "a") if args.output != "-" else sys.stdout
    for r in records:
        out.write(json.dumps(r) + "\n")
    if args.output != "-":
        out.close()
    print(f"[oura] wrote {len(records)} metrics", file=sys.stderr)
