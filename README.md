# 🎮 Game Server Backup System

Automated, multi-platform backup solution for game servers running across Docker containers and a Windows VM.

---

## 🚀 Features

* Automated backups via cron
* Google Drive integration using rclone
* Local and cloud retention policies
* Container-safe backups (stop/start during backup)
* Full restore and per-game restore support
* Cross-platform backup (Linux + Windows via SMB)
* Lightweight design (backs up only essential data)

---

## 🏗️ Architecture

* Linux host runs backup scripts
* Docker containers store game data in `/srv/data/games`
* Windows VM shares save data via SMB
* Backups stored locally and synced to Google Drive

---

## 📂 Project Structure

```
game-server-backups/
├── scripts/
│   ├── backup.sh
│   ├── restore.sh
│   └── restore-game.sh
├── config/
│   └── backup.conf
├── README.md
└── .gitignore
```

---

## ⚙️ Requirements

* Linux server (Ubuntu recommended)
* Docker
* rclone (configured with Google Drive)
* cifs-utils (for SMB mounts)

---

## 🔧 Configuration

Edit the config file:

```bash
config/backup.conf
```

Example:

```bash
BACKUP_SOURCE="/srv/data/games /srv/data/windows-saves"
BACKUP_DEST="/srv/backups"
RETENTION_DAYS_LOCAL=3
RETENTION_DAYS_CLOUD=7
```

---

## ▶️ Usage

### Run backup manually

```bash
bash /srv/data/game-server-backup/scripts/backup.sh
```

---

### Full restore

```bash
/srv/data/game-server-backup/scripts/restore.sh <backup-file> <destination>
```

---

### Restore a single game

```bash
/srv/data/game-server-backup/scripts/restore-game.sh <backup-file> <game-name>
```

Example:

```bash
restore-game.sh backup.tar.gz zomboid
```

---

## ⏱️ Automation (Cron)

Example cron job (runs twice monthly):

```bash
0 2 1,15 * * /srv/data/game-server-backup/scripts/backup.sh >> /srv/scripts/backup.log 2>&1
```

---

## ☁️ Backup Strategy

* **Local backups**: Short retention for quick restores
* **Cloud backups (Google Drive)**: Longer retention for disaster recovery
* **Windows VM saves**: Mounted via SMB and included in backups
* **Docker data**: Stored on host and backed up directly

---

## ⚠️ Notes

* Backup excludes logs, cache, and temporary files to reduce size
* Containers are stopped during backup to ensure consistency
* Credentials are stored outside the repository (`.smbcred`)
* Backup files and secrets are excluded via `.gitignore`

---

## 🧠 Future Improvements

* Backup health monitoring and alerts
* Incremental/differential backups
* Web dashboard for backup status
* Automated restore testing

---

## 📜 License

MIT

---

## 👤 Author

Aaron Schorah
