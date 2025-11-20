#!/bin/bash
set -euo pipefail

# Log file
LOG_FILE="/var/log/docker-clean.log"

echo "[$(date +"%F %T")] Starting Docker clean-up" | tee -a "$LOG_FILE"

#########################################
# Remove stopped containers              #
#########################################
echo "[$(date +"%F %T")] Removing stopped containers..." | tee -a "$LOG_FILE"
docker container prune -f | tee -a "$LOG_FILE"

#########################################
# Remove unused images                   #
#########################################
echo "[$(date +"%F %T")] Removing unused images..." | tee -a "$LOG_FILE"
docker image prune -a -f | tee -a "$LOG_FILE"

#########################################
# Remove unused networks                 #
#########################################
echo "[$(date +"%F %T")] Removing unused networks..." | tee -a "$LOG_FILE"
docker network prune -f | tee -a "$LOG_FILE"

#########################################
# Clean build cache                      #
#########################################
echo "[$(date +"%F %T")] Removing build cache..." | tee -a "$LOG_FILE"
docker builder prune -a -f | tee -a "$LOG_FILE"

#########################################
# Clean container logs                   #
#########################################
echo "[$(date +"%F %T")] Truncating large container logs..." | tee -a "$LOG_FILE"
find /var/lib/docker/containers/ -type f -name "*-json.log" -exec truncate -s 0 {} \; 2>/dev/null || true

#########################################
# Overlay2 cleanup summary               #
#########################################
echo "[$(date +"%F %T")] Checking overlay2 usage..." | tee -a "$LOG_FILE"
du -sh /var/lib/docker/overlay2 2>/dev/null | tee -a "$LOG_FILE"

echo "[$(date +"%F %T")] Docker clean-up finished ✓" | tee -a "$LOG_FILE"
