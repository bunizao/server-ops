#!/bin/bash
set -euo pipefail

#################################
# Basic backup configuration    #
#################################

# Directory to back up
SRC_DIR="/home"

# Rclone remote and destination path
REMOTE="dropbox:Backups"

# How many backup files to keep on the remote
KEEP=3

# Timestamp for the backup file
NOW="$(date +"%Y-%m-%d_%H-%M-%S")"

# Temporary archive location
ARCHIVE="/tmp/backup-${NOW}.tar.gz"

# Log file
LOG_FILE="/var/log/backup.log"

#################################
# RSS configuration             #
#################################

# Nginx web root path for RSS file
RSS_FILE="/var/www/html/backup-rss.xml"

# RSS metadata
RSS_TITLE="Backups"
# Change to your real domain or IP
RSS_LINK="https://your-domain.example/backup-rss.xml"
RSS_DESCRIPTION="Latest backup snapshots"

# How many RSS items to keep
MAX_RSS_ITEMS=10

echo "[$(date +"%F %T")] Starting backup of ${SRC_DIR} to ${REMOTE} (with RSS)" | tee -a "$LOG_FILE"

#################################
# Create archive                #
#################################

tar -czf "$ARCHIVE" \
  --exclude='*/.cache/*' \
  --exclude='*/node_modules/*' \
  --exclude='*/.npm/*' \
  --exclude='*/.cargo/registry/*' \
  -C / home

echo "[$(date +"%F %T")] Archive created: ${ARCHIVE}" | tee -a "$LOG_FILE"

#################################
# Upload to Dropbox             #
#################################

REMOTE_FILE="${REMOTE}/backup-${NOW}.tar.gz"

rclone copyto "$ARCHIVE" "$REMOTE_FILE" \
  --log-file="$LOG_FILE" --log-level=INFO

echo "[$(date +"%F %T")] Upload completed: ${REMOTE_FILE}" | tee -a "$LOG_FILE"

# Remove local temporary archive
rm -f "$ARCHIVE"
echo "[$(date +"%F %T")] Local temporary archive removed: ${ARCHIVE}" | tee -a "$LOG_FILE"

#################################
# Remote rotation               #
#################################

echo "[$(date +"%F %T")] Rotating backups on remote (keeping last ${KEEP})" | tee -a "$LOG_FILE"

mapfile -t files < <(rclone lsf "$REMOTE" --files-only | sort)

count=${#files[@]}

if (( count > KEEP )); then
  to_delete=$((count - KEEP))
  echo "[$(date +"%F %T")] Found ${count} backups, deleting ${to_delete} oldest" | tee -a "$LOG_FILE"

  for ((i=0; i<to_delete; i++)); do
    old_file="${files[$i]}"
    echo "[$(date +"%F %T")] Deleting old backup: ${REMOTE}/${old_file}" | tee -a "$LOG_FILE"
    rclone delete "${REMOTE}/${old_file}" --log-file="$LOG_FILE" --log-level=INFO
  done
else
  echo "[$(date +"%F %T")] No old backups to delete (total: ${count})" | tee -a "$LOG_FILE"
fi

#################################
# RSS update                    #
#################################

echo "[$(date +"%F %T")] Updating RSS feed: ${RSS_FILE}" | tee -a "$LOG_FILE"

PUB_DATE="$(date -R)"

NEW_ITEM=$(cat <<EOF
  <item>
    <title>Backup ${NOW}</title>
    <link>${RSS_LINK}</link>
    <description>Backup file: backup-${NOW}.tar.gz uploaded to ${REMOTE}</description>
    <pubDate>${PUB_DATE}</pubDate>
  </item>
EOF
)

if [[ -f "${RSS_FILE}" ]]; then
  EXISTING_ITEMS="$(sed -n '/<item>/,/<\/item>/p' "${RSS_FILE}")"

  ITEMS=$(printf "%s\n%s\n" "${NEW_ITEM}" "${EXISTING_ITEMS}" | \
    awk -v max="${MAX_RSS_ITEMS}" '
      /<item>/ {c++}
      { if (c <= max) print }
    ')
else
  ITEMS="${NEW_ITEM}"
fi

cat > "${RSS_FILE}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
  <title>${RSS_TITLE}</title>
  <link>${RSS_LINK}</link>
  <description>${RSS_DESCRIPTION}</description>
  <lastBuildDate>${PUB_DATE}</lastBuildDate>
${ITEMS}
</channel>
</rss>
EOF

echo "[$(date +"%F %T")] RSS feed updated successfully" | tee -a "$LOG_FILE"

echo "[$(date +"%F %T")] Backup process finished successfully ✓" | tee -a "$LOG_FILE"
