#!/bin/bash
set -e

# Load config
source /srv/data/game-server-backup/config/backup.conf

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
  echo "Error: Config not loaded properly"
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

# Delete old backups (local)
find "$BACKUP_DEST" -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS_LOCAL} -delete

# Upload to Google Drive
echo "Uploading backup to Google Drive..."
rclone copy "$BACKUP_FILE" gdrive:game-server-backups
echo "Upload complete"

# Cleanup old backups in Google Drive
echo "Cleaning old backups from Google Drive..."
rclone delete gdrive:game-server-backups --min-age "${RETENTION_DAYS_CLOUD}d"
echo "Cloud cleanup complete"

#Restarting containers
echo "Restarting containers..."

if [ -n "$RUNNING_CONTAINERS" ]; then
  docker start $RUNNING_CONTAINERS
else
  echo "Nothing to restart"
fi
