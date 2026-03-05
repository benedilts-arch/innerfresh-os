#!/bin/bash
# health-config.sh — Health pipeline configuration
#
# Copy this to ~/.config/health/config.sh and fill in your credentials.
# That file is chmod 600 and never committed.

# ── Oura Ring ─────────────────────────────────────────────────────────────────
# Get from: https://cloud.ouraring.com/personal-access-tokens
OURA_TOKEN=""

# ── Withings ─────────────────────────────────────────────────────────────────
# Get from: https://developer.withings.com/
WITHINGS_ACCESS_TOKEN=""
WITHINGS_USER_ID=""

# ── Apple Health ─────────────────────────────────────────────────────────────
# Export from Health app → your profile pic → Export All Health Data → Unzip
# Set path to the unzipped export folder:
APPLE_HEALTH_EXPORT=""   # e.g. ~/Downloads/apple_health_export

# ── Output ────────────────────────────────────────────────────────────────────
HEALTH_DIR="$HOME/.openclaw/workspace/health"
TIMELINE_FILE="$HEALTH_DIR/health-timeline.jsonl"
HEALTH_DB="$HOME/.openclaw/workspace/data/health.db"
