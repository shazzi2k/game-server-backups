#!/bin/bash
set -euo pipefail

source /etc/environment
WEBHOOK="${DISCORD_WEBHOOK}"

send_message() {
  curl -s -H "Content-Type: application/json" \
  -d "{\"content\": \"[$(TZ=Europe/London date '+%Y-%m-%d %H:%M:%S')] $1\"}" \
  "$WEBHOOK" > /dev/null
}

# Load config
source /srv/data/stacks/game-server-backups/config/backup.conf

# Validate config
if [ -z "${BACKUP_SOURCE:-}" ] || [ -z "${BACKUP_DEST:-}" ]; then
  send_message "❌ Backup failed: config not loaded"
  exit 1
fi

DATE=$(TZ=Europe/London date +"%Y-%m-%d_%H-%M")
BACKUP_FILE="$BACKUP_DEST/backup_$DATE.tar.gz"
STATUS_FILE="/srv/backups/backup_status.json"

send_message "🟡 Backup starting..."

echo "Stopping running containers..."
RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'zomboid|valheim|7days2die' || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
  docker stop $RUNNING_CONTAINERS
else
  echo "No game containers running"
fi

echo "Starting backup: $DATE"

# Create backup
tar -czf "$BACKUP_FILE" \
--exclude='*.log' \
--exclude='*output_log*' \
--exclude='*/logs/*' \
--exclude='*/cache/*' \
--exclude='*/temp/*' \
"$BACKUP_SOURCE"

send_message "🟢 Backup created: $BACKUP_FILE"

# Retention (keep last 2 safely)
find "$BACKUP_DEST" -type f -name "*.tar.gz" -printf '%T@ %p\n' \
| sort -nr \
| tail -n +3 \
| cut -d' ' -f2- \
| xargs -r rm --

send_message "🧹 Old local backups cleaned"

# Upload
FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)

echo "Uploading backup to Google Drive..."
send_message "☁️ Upload to Google Drive started..."($FILE_SIZE)"

if rclone copy "$BACKUP_FILE" gdrive:game-server-backups; then
  UPLOAD_SUCCESS=true
  send_message "☁️ Backup uploaded to Google Drive"
else
  UPLOAD_SUCCESS=false
  send_message "❌ Backup upload FAILED"
fi

# Cloud cleanup
echo "Cleaning old backups from Google Drive..."
rclone delete gdrive:game-server-backups --min-age "${RETENTION_DAYS_CLOUD}d"
send_message "🧹 Cloud backups cleaned"

# Restart containers
echo "Restarting containers..."
if [ -n "$RUNNING_CONTAINERS" ]; then
  docker start $RUNNING_CONTAINERS
fi

send_message "🔵 Backup process complete. Servers back online."

# Update status file
NEW_ENTRY=$(cat <<EOF
{
  "time": "$(TZ=Europe/London date '+%Y-%m-%d %H:%M:%S')",
  "status": "true",
  "upload": "$UPLOAD_SUCCESS",
  "file": "$(basename "$BACKUP_FILE")"
}
EOF
)

if [ -f "$STATUS_FILE" ]; then
  jq ". |= [$NEW_ENTRY] + . | .[:5]" "$STATUS_FILE" > /tmp/tmp_backup.json && mv /tmp/tmp_backup.json "$STATUS_FILE"
else
  echo "[$NEW_ENTRY]" > "$STATUS_FILE"
fi
