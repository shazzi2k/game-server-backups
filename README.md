# Game Server Backup System

Automated backup solution for:
- Docker-based game servers (Zomboid, Valheim, 7DTD)
- Windows VM game saves (DCS, Sons of the Forest)

## Features

- Automated backups with cron
- Google Drive integration via rclone
- Local + cloud retention policies
- Container-safe backups (stop/start)
- Restore scripts (full + per-game)
- Cross-platform backup (Linux + Windows SMB)

## Structure

- `/scripts/backup.sh` - Main backup script
- `/scripts/restore.sh` - Full restore
- `/scripts/restore-game.sh` - Partial restore
- `/config/backup.conf` - Configuration

## Requirements

- Linux server
- Docker
- rclone (Google Drive)
- CIFS utils (for Windows shares)

## Usage

Run backup manually:
```bash
bash /srv/scripts/backup.sh

## Restore

/srv/scripts/restore.sh <backup-file> <destination>


