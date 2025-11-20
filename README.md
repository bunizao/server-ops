# server-ops

server-ops is a curated set of Bash automation scripts that keep a single self-hosted machine healthy: recurring filesystem backups pushed through `rclone` and periodic Docker hygiene tasks. Each script runs with `set -euo pipefail`, logs to `/var/log`, and is safe to schedule via cron or systemd timers.

## What's inside

- `scripts/backup/backup.sh`: Archive `/home` and upload it through `rclone`, trimming remote snapshots.
- `scripts/backup/backup-with-rss.sh`: Same backup workflow but also exposes an RSS feed with the latest snapshot info.
- `scripts/clean/clean-docker.sh`: Sweep stopped containers, unused images/networks, build cache, and heavy container logs.

Need more detail? Check the per-folder docs:

- [Backup scripts documentation](scripts/backup/README.md) — includes the rclone setup guide, configurable variables, and cron examples.
- [Docker clean-up documentation](scripts/clean/README.md) — covers what gets pruned and how to schedule the job safely.

## Quick start

1. **Install the prerequisites.**
   - Backups require `tar` plus `rclone` (configured via `rclone config` with your remote such as Dropbox or S3).
   - Docker cleanup requires the Docker CLI and permission to run pruning commands.
2. **Adjust variables.** Edit the top of each script to point to your directories and remotes (e.g., `SRC_DIR`, `REMOTE`, `KEEP`, `RSS_FILE`, `LOG_FILE`).
3. **Test locally.** Run the scripts manually once on a staging host and inspect `/var/log/*.log` along with the remote storage or `docker` output.
4. **Automate.** Add cron entries or systemd timers; see the linked backup documentation for example schedules.

## Contributing

Improvements and new automation scripts are welcome.

- Keep related scripts grouped under their own subdirectories inside `scripts/`.
- Update the folder-specific README (e.g., `scripts/backup/README.md`) whenever you add or modify a script so others understand the requirements and variables.
