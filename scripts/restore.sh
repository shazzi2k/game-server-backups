#!/bin/bash
set -e

BACKUP_FILE=$1
RESTORE_DEST=$2

if [ -z "$BACKUP_FILE" ] || [ -z "$RESTORE_DEST" ]; then
  echo "Usage: restore.sh <backup-file> <restore-destination>"
  exit 1
fi

echo "Starting restore from: $BACKUP_FILE"
echo "Restoring to: $RESTORE_DEST"

mkdir -p "$RESTORE_DEST"
tar -xzf "$BACKUP_FILE" -C /  srv/data/games

echo "Restore complete"
