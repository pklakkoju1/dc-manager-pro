#!/bin/sh
# DC Manager Pro — Backup container entrypoint
# Env vars: PGPASSWORD, DB_USER, DB_NAME

mkdir -p /backups/daily /backups/weekly /backups/manual

cat > /etc/crontabs/root << CRON
0 2 * * * pg_dump -h db -U $DB_USER $DB_NAME | gzip > /backups/daily/${DB_NAME}_$(date +\%Y-\%m-\%d_\%H\%M\%S).sql.gz >> /backups/backup.log 2>&1
0 3 * * 0 cp /backups/daily/${DB_NAME}_*.sql.gz /backups/weekly/ 2>/dev/null; find /backups/weekly -name "*.sql.gz" -mtime +84 -delete
0 4 * * * find /backups/daily -name "*.sql.gz" -mtime +30 -delete
CRON

echo "$(date) Backup scheduler started. Daily at 02:00, weekly on Sunday at 03:00." | tee /backups/backup.log
exec crond -f -d 6
