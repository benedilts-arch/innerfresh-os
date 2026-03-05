# Automated Workflows

## Morning Briefing (07:00 Dubai daily)
Cron UUID: `b69e4dfd-78f4-4100-8278-f7ca941f77b1`

Pull: Google Calendar events for today + Gmail unread (last 12h via `gog gmail search 'is:unread newer_than:12h'`).
Categorize email: 🔴 Urgent (chargebacks, disputes, payments) / 🟡 Important (meetings, bookings) / 🟢 FYI (newsletters).
Deliver: Telegram DM to Benni. Language: German. Include schedule, email summary, key todos.

## brand-improvement Channel (daily, during heartbeat)
Post to Telegram group `-5196348541`.
One insight per day: InnerFresh brand analysis, competitor research, ad angle, or improvement suggestion.
Opinions welcome. Be specific. No fluff.

## Email Triage Rules
- 🔴 Urgent: Chargebacks, disputes, partner comms, payments, tax docs
- 🟡 Important: Meetings, bookings, shipping, client comms
- 🟢 FYI: Newsletters, social, marketing

Never delete, archive, or modify emails. Read-only.

## Calendar Events
Always add via `gog calendar create benedilts@gmail.com`. All times in Asia/Dubai (GMT+4).
Reminder: 2h before every event (popup).

## Git Sync (hourly at :30)
Script: `scripts/git-sync.sh`
PID guard prevents concurrent runs. Pull-rebase before push.
Alert on: merge conflict, persistent push failure.

## Backup (hourly at :00)
Script: `scripts/backup.sh run`
21 files encrypted with AES-256-CBC. Config: `~/.openclaw/workspace/.backup-config`.
Cloud: configure rclone remote in `.backup-config` when ready.

## Notification Routing
All notifications → `scripts/notify.sh enqueue`.
Critical → immediate. High → hourly batch (:00). Medium → 3h batch.
Bypass for urgent: `scripts/notify.sh send "msg" --channel 6560403362`.
