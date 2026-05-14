#!/bin/bash
set -euo pipefail
# curl flags:
#   -sS              silent progress, but surface errors
#   --fail-with-body return nonzero on HTTP 4xx/5xx and still print body
#   --max-redirs 0   treat any 3xx redirect as a failure (catches /login bounces)
# Without these, curl -s returned exit 0 even when the route 502'd or 307'd,
# so cron-wrapper.sh thought every fire succeeded and Slack never alerted.
echo "${CRON_SCHEDULE} /usr/local/bin/cron-wrapper.sh curl -sS --fail-with-body --max-redirs 0 -X POST \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer ${CRON_SECRET}' \
  -H 'x-cron-secret: ${CRON_SECRET}' \
  -H 'x-session-secret: ${SESSION_SECRET}' \
  '${BASE_URL}${CRON_ENDPOINT}'" > /var/spool/cron/crontabs/root
crond -f -l 2
