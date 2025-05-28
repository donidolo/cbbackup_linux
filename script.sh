#!/bin/bash

archive="/data/BackupCLI"
repo="daily"
cluster="couchbases://cb.g4g6gid6hsehih9a.cloud.couchbase.com"
username="user"
password="Asdf1234!"

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
backupRepoPath="$archive/$repo"
tarPath="$backupRepoPath/${repo}_$timestamp.tar.gz"
logFile="$backupRepoPath/backup_$timestamp.txt"

echo "[INFO] Starting backup at $(date)"

# Run Couchbase backup
/data/Couchbase/Installer/couchbase-server-admin-tools-7.6.4-5146/bin/cbbackupmgr backup \
--archive "$archive" \
--repo "$repo" \
--cluster "$cluster" \
--username "$username" \
--password "$password" \
--full-backup \
--threads 4

if [ $? -eq 0 ]; then
echo "[INFO] Backup completed successfully."

# Find the latest backup folder (modified in the last minute)
latestFolder=$(find "$backupRepoPath" -maxdepth 1 -type d -newermt "-1 minute" ! -path "$backupRepoPath" | sort | tail -n 1)

if [ -z "$latestFolder" ]; then
echo "[ERROR] No backup folder found to archive."
echo "[ERROR] No backup folder found to archive at $(date)" > "$logFile"
exit 1
fi

# Create tar.gz archive
tar -czf "$tarPath" -C "$latestFolder" .
if [ $? -eq 0 ]; then
echo "[INFO] Backup archived to: $tarPath"

# Remove original folder
rm -rf "$latestFolder"
echo "[INFO] Removed original backup folder: $latestFolder"

# Retention: Delete .tar.gz files older than 7 days
find "$backupRepoPath" -name "${repo}_*.tar.gz" -type f -mtime +7 -exec rm -f {} \;
echo "[INFO] Old tar.gz files older than 7 days deleted."

{
echo "[INFO] Backup completed successfully at $(date)"
echo "[INFO] Backup archived to: $tarPath"
echo "[INFO] Removed original backup folder: $latestFolder"
echo "[INFO] Old tar.gz files older than 7 days deleted."
} > "$logFile"
else
echo "[ERROR] Archiving backup failed!"
echo "[ERROR] Archiving backup failed at $(date)" > "$logFile"
fi
else
echo "[ERROR] Backup failed!"
echo "[ERROR] Backup failed at $(date)" > "$logFile"
fi

echo "[INFO] Backup script finished at $(date)"
