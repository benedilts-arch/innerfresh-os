#!/usr/bin/env python3
"""
Eight Sleep connector — pulls sleep stages, HRV, heart rate, temperature, scores.
Uses the unofficial Eight Sleep API (same one the app uses).

Metrics extracted:
  sleep_score, hrv, heart_rate, respiratory_rate, sleep_duration,
  sleep_efficiency, time_to_sleep, bed_temp_c, room_temp_c,
  stage_awake, stage_light, stage_deep, stage_rem

Usage:
  python3 eight_sleep.py --days 7
  python3 eight_sleep.py --days 7 --output health-timeline.jsonl
"""

import os, sys, json, subprocess, urllib.request, urllib.parse
from datetime import datetime, timedelta, timezone, date
from pathlib import Path

BASE_URL = "https://client-api.8slp.net/v1"
APP_VERSION = "6.14.0"
USER_AGENT = f"okhttp/4.9.3"

def load_config():
    result = subprocess.run(
        ["bash", "-c", "source ~/.config/health/config.sh 2>/dev/null && "
         "echo EIGHT_SLEEP_EMAIL=$EIGHT_SLEEP_EMAIL && "
         "echo EIGHT_SLEEP_PASSWORD=$EIGHT_SLEEP_PASSWORD && "
         "echo EIGHT_SLEEP_TOKEN=$EIGHT_SLEEP_TOKEN && "
         "echo EIGHT_SLEEP_USER_ID=$EIGHT_SLEEP_USER_ID"],
        capture_output=True, text=True
    )
    cfg = {}
    for line in result.stdout.splitlines():
        if "=" in line:
            k, v = line.split("=", 1)
            cfg[k.strip()] = v.strip()
    return cfg

def login(email: str, password: str) -> tuple[str, str]:
    """Login and return (access_token, user_id)."""
    payload = json.dumps({"email": email, "password": password}).encode()
    req = urllib.request.Request(
        f"{BASE_URL}/login",
        data=payload,
        headers={"Content-Type": "application/json", "User-Agent": USER_AGENT},
        method="POST"
    )
    with urllib.request.urlopen(req, timeout=15) as r:
        data = json.loads(r.read())
    session = data.get("session", {})
    token = session.get("token", "")
    user_id = session.get("userId", "")
    return token, user_id

def api_get(path: str, token: str) -> dict:
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        headers={"Authorization": f"Bearer {token}", "User-Agent": USER_AGENT}
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            return json.loads(r.read())
    except Exception as e:
        print(f"[eight_sleep] API error {path}: {e}", file=sys.stderr)
        return {}

def save_tokens(token: str, user_id: str):
    """Cache token so we don't re-login every run."""
    cache = {"token": token, "user_id": user_id}
    cache_path = Path.home() / ".config" / "health" / ".eight_sleep_session.json"
    cache_path.parent.mkdir(parents=True, exist_ok=True)
    cache_path.write_text(json.dumps(cache))
    cache_path.chmod(0o600)

def load_cached_tokens() -> tuple[str, str]:
    cache_path = Path.home() / ".config" / "health" / ".eight_sleep_session.json"
    if cache_path.exists():
        try:
            d = json.loads(cache_path.read_text())
            return d.get("token", ""), d.get("user_id", "")
        except: pass
    return "", ""

def normalize_interval(interval: dict) -> list:
    """Convert one Eight Sleep sleep interval to metric records."""
    records = []

    ts = interval.get("ts", interval.get("timeseries", {}).get("tempBedC", [[]])[0][0] if interval.get("timeseries") else "")
    if not ts:
        ts = datetime.now(timezone.utc).isoformat()

    score = interval.get("score")
    if score:
        records.append({"timestamp": ts, "source": "eight_sleep", "metric": "sleep_score", "value": score, "unit": "score"})

    stages = interval.get("stages", [])
    stage_totals = {}
    for stage in stages:
        name = stage.get("stage", "")
        dur = stage.get("duration", 0)
        if name:
            stage_totals[name] = stage_totals.get(name, 0) + dur

    for stage_name, total_seconds in stage_totals.items():
        records.append({
            "timestamp": ts, "source": "eight_sleep",
            "metric": f"stage_{stage_name}", "value": total_seconds, "unit": "seconds"
        })

    # Timeseries averages (HRV, HR, resp rate, temp)
    timeseries = interval.get("timeseries", {})
    ts_metrics = {
        "hrv":          ("hrv", "ms"),
        "heartRate":    ("heart_rate", "bpm"),
        "respiratoryRate": ("respiratory_rate", "breaths/min"),
        "tempBedC":     ("bed_temp_c", "celsius"),
        "tempRoomC":    ("room_temp_c", "celsius"),
    }
    for key, (metric, unit) in ts_metrics.items():
        series = timeseries.get(key, [])
        if series:
            values = [s[1] for s in series if len(s) > 1 and s[1] is not None]
            if values:
                avg = round(sum(values) / len(values), 2)
                records.append({"timestamp": ts, "source": "eight_sleep", "metric": metric, "value": avg, "unit": unit})

    # Sleep duration
    duration = interval.get("duration")
    if duration:
        records.append({"timestamp": ts, "source": "eight_sleep", "metric": "sleep_duration", "value": duration, "unit": "seconds"})

    # Sleep efficiency
    total_sleep = stage_totals.get("light", 0) + stage_totals.get("deep", 0) + stage_totals.get("rem", 0)
    total_time = sum(stage_totals.values())
    if total_time > 0:
        efficiency = round(total_sleep / total_time * 100, 1)
        records.append({"timestamp": ts, "source": "eight_sleep", "metric": "sleep_efficiency", "value": efficiency, "unit": "percent"})

    # Time to sleep (latency)
    tts = interval.get("timeToSleep")
    if tts:
        records.append({"timestamp": ts, "source": "eight_sleep", "metric": "time_to_sleep", "value": tts, "unit": "seconds"})

    return records

def run(days: int = 7) -> list:
    cfg = load_config()

    # Try cached token first
    token, user_id = load_cached_tokens()

    # Re-login if no cached token
    if not token:
        email = cfg.get("EIGHT_SLEEP_EMAIL", os.environ.get("EIGHT_SLEEP_EMAIL", ""))
        password = cfg.get("EIGHT_SLEEP_PASSWORD", os.environ.get("EIGHT_SLEEP_PASSWORD", ""))
        if not email or not password:
            print("[eight_sleep] No credentials. Set EIGHT_SLEEP_EMAIL + EIGHT_SLEEP_PASSWORD in ~/.config/health/config.sh", file=sys.stderr)
            return []
        try:
            token, user_id = login(email, password)
            save_tokens(token, user_id)
            print(f"[eight_sleep] Logged in, user_id={user_id}", file=sys.stderr)
        except Exception as e:
            print(f"[eight_sleep] Login failed: {e}", file=sys.stderr)
            return []

    if not user_id:
        user_id = cfg.get("EIGHT_SLEEP_USER_ID", "")

    # Fetch sleep intervals
    start_date = (date.today() - timedelta(days=days)).isoformat()
    end_date = date.today().isoformat()

    data = api_get(f"/users/{user_id}/intervals?start={start_date}&end={end_date}", token)
    intervals = data.get("data", {}).get("intervals", data.get("intervals", []))

    if not intervals and token:
        # Token may have expired — retry with fresh login
        email = cfg.get("EIGHT_SLEEP_EMAIL", "")
        password = cfg.get("EIGHT_SLEEP_PASSWORD", "")
        if email and password:
            try:
                token, user_id = login(email, password)
                save_tokens(token, user_id)
                data = api_get(f"/users/{user_id}/intervals?start={start_date}&end={end_date}", token)
                intervals = data.get("data", {}).get("intervals", data.get("intervals", []))
            except Exception as e:
                print(f"[eight_sleep] Token refresh failed: {e}", file=sys.stderr)

    print(f"[eight_sleep] {len(intervals)} sleep intervals", file=sys.stderr)

    all_records = []
    for interval in intervals:
        all_records.extend(normalize_interval(interval))

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
    print(f"[eight_sleep] wrote {len(records)} metrics", file=sys.stderr)
