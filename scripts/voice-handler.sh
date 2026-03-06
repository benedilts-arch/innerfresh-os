#!/bin/bash
# voice-handler.sh — transcribe incoming Telegram voice messages
# Called by cron every 5s; finds new .ogg files and transcribes them

INBOUND_DIR="${HOME}/.openclaw/media/inbound"
WHISPER_CACHE="/tmp/whisper-out"
mkdir -p "$WHISPER_CACHE"

# Find .ogg files modified in last 30 seconds
find "$INBOUND_DIR" -name "*.ogg" -mmin -1 2>/dev/null | while read -r ogg_file; do
  # Avoid double-processing
  lock_file="/tmp/voice-$(basename "$ogg_file").lock"
  [ -f "$lock_file" ] && continue
  touch "$lock_file"

  # Transcribe (auto-detect language, tiny model)
  whisper "$ogg_file" \
    --model tiny \
    --output_format txt \
    --output_dir "$WHISPER_CACHE" \
    --fp16 False \
    2>/dev/null

  # Read result
  base=$(basename "$ogg_file" .ogg)
  txt_file="$WHISPER_CACHE/${base}.txt"
  
  if [ -f "$txt_file" ]; then
    text=$(cat "$txt_file" | tr -d '\n' | xargs)
    if [ -n "$text" ]; then
      # The main agent session will see this and respond naturally
      echo "🎙️ Voice note transcribed: $text"
    fi
    rm -f "$txt_file"
  fi

  # Cleanup
  rm -f "$ogg_file" "$lock_file"
done
