#!/bin/bash

echo "[backup] starting backup job" >> /var/log/app/app.log

cd /var/backup/run

PYTHONPATH="/var/backup/run:/opt/backup" \
    /usr/bin/python3 -c "import backup; backup.main()"

echo "[backup] completed" >> /var/log/app/app.log