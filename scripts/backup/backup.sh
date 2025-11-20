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

echo "[$(date +"%F %T")] Starting backup of ${SRC_DIR} to ${REMOTE}" | tee -a "$LOG_FILE"

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

REMOTE_FILE="${REMOTE}/home-backup-${NOW}.tar.gz"

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

# List backup files on remote, sorted by name
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

echo "[$(date +"%F %T")] Backup process finished successfully ✓" | tee -a "$LOG_FILE"
