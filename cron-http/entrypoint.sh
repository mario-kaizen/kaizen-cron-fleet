#!/bin/bash
set -euo pipefail
echo "${CRON_SCHEDULE} /usr/local/bin/cron-wrapper.sh curl -s -X POST \
  -H 'Content-Type: application/json' \
  -H 'x-cron-secret: ${CRON_SECRET}' \
  -H 'x-session-secret: ${SESSION_SECRET}' \
  '${BASE_URL}${CRON_ENDPOINT}'" > /var/spool/cron/crontabs/root
crond -f -l 2
