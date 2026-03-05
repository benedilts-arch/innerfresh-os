# ERRORS.md — Recurring Error Patterns

Patterns encountered in production. Used to avoid repeat failures.

---

## Pattern: macOS vs Linux bash incompatibilities
- `date +%s%3N` → use python3 for ms timestamps
- `${VAR^}` → use awk or python3
- `gtimeout` vs `timeout` → install `coreutils` via brew for GNU timeout
- `stat -f` vs `stat -c` → macOS uses `-f`, Linux uses `-c`

## Pattern: SQLite INSERT with shell variables containing quotes
- Single quotes in description fields break SQL strings
- Fix: always `sed "s/'/''/g"` on user-controlled strings before inserting

## Pattern: gog CLI requires interactive session for first auth
- Background cron sessions can't complete OAuth flow
- Fix: always auth interactively first, then background sessions work via Keychain

## Pattern: OpenClaw cron editing by name fails
- `openclaw cron edit --name X` doesn't work; must use UUID
- Workaround: always save UUID when creating a cron job

## Pattern: Telegram bot doesn't receive group messages after Privacy Mode change
- Telegram caches group membership settings at join time
- Fix: remove bot from group and re-add after any BotFather config change

## Pattern: pip3 install blocked by PEP 668 on macOS
- System Python blocks installs without `--break-system-packages`
- Fix: always use `pip3 install X --break-system-packages` or use a venv
