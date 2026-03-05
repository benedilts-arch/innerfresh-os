#!/usr/bin/env python3
"""
Apple Health connector — parses XML export or CSV summary files.
Normalizes to: {timestamp, source, metric, value, unit}

Usage:
  python3 apple_health.py --export ~/Downloads/apple_health_export --days 7
"""

import os, sys, json, subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

METRIC_MAP = {
    "HKQuantityTypeIdentifierStepCount":           ("steps", "count"),
    "HKQuantityTypeIdentifierHeartRate":           ("heart_rate", "bpm"),
    "HKQuantityTypeIdentifierRestingHeartRate":    ("resting_hr", "bpm"),
    "HKQuantityTypeIdentifierHeartRateVariabilitySDNN": ("hrv_sdnn", "ms"),
    "HKQuantityTypeIdentifierActiveEnergyBurned":  ("active_calories", "kcal"),
    "HKQuantityTypeIdentifierBasalEnergyBurned":   ("basal_calories", "kcal"),
    "HKQuantityTypeIdentifierBodyMass":            ("weight", "kg"),
    "HKQuantityTypeIdentifierBodyFatPercentage":   ("body_fat", "percent"),
    "HKQuantityTypeIdentifierVO2Max":              ("vo2max", "mL/kg/min"),
    "HKCategoryTypeIdentifierSleepAnalysis":       ("sleep", "stage"),
    "HKQuantityTypeIdentifierDistanceWalkingRunning": ("distance", "km"),
    "HKQuantityTypeIdentifierFlightsClimbed":      ("flights_climbed", "count"),
}

def parse_export_xml(export_path: Path, days: int = 7) -> list:
    """Parse Apple Health export.xml (large file — use iterparse)."""
    import xml.etree.ElementTree as ET

    xml_file = export_path / "apple_health_export" / "export.xml"
    if not xml_file.exists():
        xml_file = export_path / "export.xml"
    if not xml_file.exists():
        print(f"[apple_health] export.xml not found at {export_path}", file=sys.stderr)
        return []

    cutoff = datetime.now(timezone.utc) - timedelta(days=days)
    records = []
    count = 0

    print(f"[apple_health] Parsing {xml_file} (this may take a moment)...", file=sys.stderr)
    for event, elem in ET.iterparse(str(xml_file), events=("end",)):
        if elem.tag != "Record":
            elem.clear()
            continue

        rec_type = elem.get("type", "")
        if rec_type not in METRIC_MAP:
            elem.clear()
            continue

        metric, unit = METRIC_MAP[rec_type]
        ts_str = elem.get("startDate", "")
        try:
            ts = datetime.fromisoformat(ts_str.replace(" ", "T").replace("+0000", "+00:00"))
            if ts < cutoff:
                elem.clear()
                continue
        except:
            elem.clear()
            continue

        value_str = elem.get("value", "")
        try:
            value = float(value_str)
        except:
            value = value_str

        override_unit = elem.get("unit", unit)
        records.append({
            "timestamp": ts.isoformat(),
            "source": "apple_health",
            "metric": metric,
            "value": value,
            "unit": override_unit
        })
        count += 1
        elem.clear()

    print(f"[apple_health] parsed {count} records from XML", file=sys.stderr)
    return records

def run(export_path: str = None, days: int = 7) -> list:
    if not export_path:
        result = subprocess.run(
            ["bash", "-c", f"source ~/.config/health/config.sh 2>/dev/null && echo $APPLE_HEALTH_EXPORT"],
            capture_output=True, text=True
        )
        export_path = result.stdout.strip()

    if not export_path:
        print("[apple_health] No export path configured. Set APPLE_HEALTH_EXPORT in ~/.config/health/config.sh", file=sys.stderr)
        return []

    return parse_export_xml(Path(export_path).expanduser(), days)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--export", default=None)
    parser.add_argument("--days", type=int, default=7)
    parser.add_argument("--output", default="-")
    args = parser.parse_args()

    records = run(args.export, args.days)
    out = open(args.output, "a") if args.output != "-" else sys.stdout
    for r in records:
        out.write(json.dumps(r) + "\n")
    if args.output != "-":
        out.close()
    print(f"[apple_health] wrote {len(records)} metrics", file=sys.stderr)
