# Backup scripts

Two Bash scripts live here:

| Script | Purpose |
| --- | --- |
| `backup.sh` | Compresses `SRC_DIR` (defaults to `/home`), uploads the archive to an `rclone` remote, and enforces remote-side retention by keeping only the newest `KEEP` files |
| `backup-with-rss.sh` | Runs the same backup flow and then updates an RSS feed so you can subscribe to backup events |

All scripts run with `set -euo pipefail`, write progress to `/var/log/backup.log`, and assume root privileges so they can reach `/home`, `/tmp`, `/var/log`, or your web root.

## Dependencies

- `tar` for creating the archive.
- `rclone` for moving the archive to the remote destination and for listing/deleting remote files.
- Adequate disk space on the filesystem that holds `ARCHIVE` (default `/tmp`).
- For the RSS script: write access to the HTTP-served directory that hosts the RSS file (default `/var/www/html`).

## Configure `rclone`

Both scripts require a working `rclone` remote. Configure it once on the host:

1. Install rclone from your package manager or the official installer.
2. Run `rclone config` and follow the prompts:
   - Choose `n` for a new remote and give it a memorable name (e.g., `dropbox`).
   - Select the backend type (Dropbox, S3, etc.) and authorize access.
   - Test the connection with `rclone lsf dropbox:` to make sure credentials work.
3. Point the script’s `REMOTE` variable to that remote plus a folder, such as `dropbox:Backups`.

## Key variables (edit at the top of the scripts)

| Variable | Description |
| --- | --- |
| `SRC_DIR` | Absolute path to the directory tree you want to back up. Default `/home`. |
| `REMOTE` | `rclone` remote and folder (e.g., `dropbox:Backups`). Must exist in your `rclone` config. |
| `KEEP` | Number of archives to keep on the remote. Oldest ones are deleted beyond this limit. |
| `NOW` | Timestamp used in filenames. Usually no need to change. |
| `ARCHIVE` | Temporary archive path, default `/tmp/backup-<timestamp>.tar.gz`. Adjust if `/tmp` is small. |
| `LOG_FILE` | Log destination (default `/var/log/backup.log`). |
| `RSS_FILE` | (RSS script only) Absolute path to the XML feed, default `/var/www/html/backup-rss.xml`. |
| `RSS_TITLE` / `RSS_LINK` / `RSS_DESCRIPTION` | RSS metadata exposed to subscribers. Set `RSS_LINK` to a public URL that hosts the feed. |
| `MAX_RSS_ITEMS` | Number of `<item>` entries kept in the RSS file. |

## Cron examples

Schedule the scripts through cron (replace paths to match your deployment):

```cron
# Baseline backup every day at 02:00
0 2 * * * /usr/local/bin/bash /path/to/repo/scripts/backup/backup.sh >> /var/log/backup.log 2>&1

# RSS-enabled backup every Sunday at 03:00
0 3 * * 0 /usr/local/bin/bash /path/to/repo/scripts/backup/backup-with-rss.sh >> /var/log/backup.log 2>&1
```

Tips:

- Ensure `/usr/local/bin/bash` and `/path/to/repo` match your actual paths.
- Cron runs with a limited `PATH`, so use absolute paths to `rclone` if it lives outside standard locations.
- Consider staggering execution times to avoid overlapping jobs when both scripts are enabled.

## Manual run checklist

1. Run `rclone lsf <REMOTE>` manually to confirm connectivity.
2. Execute the script once interactively (`sudo bash backup.sh`) on a staging host.
3. Inspect `/var/log/backup.log`, ensure the remote contains the new archive, and confirm old snapshots rotate as expected.
4. (RSS script) Visit `RSS_LINK` in a browser or RSS reader to ensure it serves the XML file.

