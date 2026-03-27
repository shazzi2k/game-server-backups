#!/bin/bash
set -e

WEBHOOK="${DISCORD_WEBHOOK}"

send_message() {
  curl -s -H "Content-Type: application/json" \
  -d "{\"content\": \"[$(date '+%Y-%m-%d %H:%M:%S')] $1\"}" \
  "$WEBHOOK" > /dev/null
}

# Load config
source /srv/data/stacks/game-server-backups/config/backup.conf

send_message "🟡 Backup starting..."

# Stop active containers
echo "Stopping running containers..."

RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | grep -E 'zomboid|valheim|7days2die' || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
  docker stop $RUNNING_CONTAINERS
else
  echo "No game containers running"
fi

# Validate config
if [ -z "$BACKUP_SOURCE" ] || [ -z "$BACKUP_DEST" ]; then
  send_message "❌ Backup failed: config not loaded"
  exit 1
fi

DATE=$(date +"%Y-%m-%d_%H-%M")
BACKUP_FILE="$BACKUP_DEST/backup_$DATE.tar.gz"

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

# Retention (local - keep last 2)
ls -tp "$BACKUP_DEST"/*.tar.gz | grep -v '/$' | tail -n +3 | xargs -r rm --

send_message "🧹 Old local backups cleaned"

# Upload to Google Drive
echo "Uploading backup to Google Drive..."
rclone copy "$BACKUP_FILE" gdrive:game-server-backups
echo "Upload complete"

send_message "☁️ Backup uploaded to Google Drive"

# Cleanup old backups in Google Drive
echo "Cleaning old backups from Google Drive..."
rclone delete gdrive:game-server-backups --min-age "${RETENTION_DAYS_CLOUD}d"
echo "Cloud cleanup complete"

send_message "🧹 Cloud backups cleaned"

# Restarting containers
echo "Restarting containers..."

if [ -n "$RUNNING_CONTAINERS" ]; then
  docker start $RUNNING_CONTAINERS
else
  echo "Nothing to restart"
fi

send_message "🔵 Backup process complete. Servers back online."
