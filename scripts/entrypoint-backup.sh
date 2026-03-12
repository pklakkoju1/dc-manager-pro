#!/bin/sh
# DC Manager Pro — Backup container entrypoint
# Env vars passed in: PGPASSWORD, DB_USER, DB_NAME

mkdir -p /backups/daily /backups/weekly /backups/manual

# Write crontab file
cat > /etc/crontabs/root << CRON
0 2 * * * pg_dump -h db -U $DB_USER $DB_NAME | gzip > /backups/daily/${DB_NAME}_$(date +\%Y-\%m-\%d_\%H\%M\%S).sql.gz >> /backups/backup.log 2>&1
CRON

echo "$(date) Backup scheduler started. Daily backups at 02:00 AM." | tee /backups/backup.log
exec crond -f -d 6
