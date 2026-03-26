#!/bin/bash
set -e

BACKUP_FILE=$1
GAME=$2

if [ -z "$BACKUP_FILE" ] || [ -z "$GAME" ]; then
  echo "Usage: restore-game.sh <backup-file> <game-folder>"
  echo "Example: restore-game.sh backup.tar.gz zomboid"
  exit 1
fi

echo "Restoring game: $GAME"
echo "From backup: $BACKUP_FILE"

# Stop container if running (optional but safer)
if docker ps --format '{{.Names}}' | grep -q "$GAME"; then
  echo "Stopping container: $GAME"
  docker stop "$GAME"
fi

# Restore only that game folder
tar -xzf "$BACKUP_FILE" -C / "srv/data/games/$GAME"

echo "Restore complete for $GAME"

# Restart container if it was running
if docker ps -a --format '{{.Names}}' | grep -q "$GAME"; then
  echo "Starting container: $GAME"
  docker start "$GAME"
fi
