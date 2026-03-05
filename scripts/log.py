#!/usr/bin/env python3
"""
log.py — Structured event logger (Python library + CLI)

Library usage:
    from log import logger
    log = logger("email-scan")
    log.info("Scanned 12 threads", count=12)
    log.error("API failed", status=429)

CLI usage:
    python3 log.py --event email-scan --level info --msg "Scanned 12" --count 12
"""

import json, os, re, sys, time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

LOG_DIR = Path.home() / ".openclaw" / "workspace" / "data" / "logs"
LOG_DIR.mkdir(parents=True, exist_ok=True)

_SECRET_PATTERNS = [
    re.compile(r'sk-[A-Za-z0-9]{20,}'),
    re.compile(r'ntn_[A-Za-z0-9]+'),
    re.compile(r'Bearer [A-Za-z0-9\-\._~\+\/]+'),
    re.compile(r'AKIA[0-9A-Z]{16}'),
    re.compile(r'AIza[0-9A-Za-z\-_]{35}'),
    re.compile(r'bot[0-9]+:[A-Za-z0-9\-_]+'),
]

def _redact(text: str) -> str:
    for p in _SECRET_PATTERNS:
        text = p.sub('[REDACTED]', text)
    return text

def _redact_obj(obj: Any) -> Any:
    if isinstance(obj, str):
        return _redact(obj)
    if isinstance(obj, dict):
        return {k: _redact_obj(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_redact_obj(i) for i in obj]
    return obj

def _write(event: str, level: str, msg: str, **fields):
    entry = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "event": event,
        "level": level,
        "msg": _redact(msg),
        **_redact_obj(fields)
    }
    line = json.dumps(entry, ensure_ascii=False) + "\n"

    # Per-event file
    event_file = LOG_DIR / f"{event}.jsonl"
    with open(event_file, "a") as f:
        f.write(line)

    # Unified stream
    all_file = LOG_DIR / "all.jsonl"
    with open(all_file, "a") as f:
        f.write(line)

class Logger:
    def __init__(self, event: str):
        self.event = event

    def debug(self, msg: str, **fields):
        _write(self.event, "debug", msg, **fields)

    def info(self, msg: str, **fields):
        _write(self.event, "info", msg, **fields)

    def warn(self, msg: str, **fields):
        _write(self.event, "warn", msg, **fields)

    def error(self, msg: str, **fields):
        _write(self.event, "error", msg, **fields)

    def critical(self, msg: str, **fields):
        _write(self.event, "critical", msg, **fields)

def logger(event: str) -> Logger:
    return Logger(event)

# ── CLI ──────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--event", required=True)
    parser.add_argument("--level", default="info", choices=["debug","info","warn","error","critical"])
    parser.add_argument("--msg", required=True)
    parser.add_argument("--fields", default="{}", help="Extra JSON fields")
    args = parser.parse_args()
    extra = json.loads(args.fields)
    _write(args.event, args.level, args.msg, **extra)
    print(f"[{args.level}] {args.event}: {args.msg}")
