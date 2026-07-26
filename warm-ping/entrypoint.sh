#!/bin/bash
set -euo pipefail
# curl flags:
#   -s        silent (no progress meter)
#   -o /dev/null   discard the response body, we only care that the route ran
#   -f        fail (nonzero exit) on HTTP 4xx/5xx so cron-wrapper.sh notices
#             and alerts Slack instead of quietly reporting success on a
#             misconfigured key or a downed app. Same lesson the rest of the
#             fleet already learned in a38bd4b: curl -s alone treats any
#             response, including an error page, as a clean run.
#   -m 35     hard timeout, above the ~25-30s cold path so a post-restart
#             warm-up is never mistaken for a stuck ping
# This is a GET-only warm ping: the target route exports GET only and
# 405s on POST, so it does not use the shared cron-http image's hardcoded
# POST + x-cron-secret/x-session-secret request shape.
echo "${CRON_SCHEDULE} /usr/local/bin/cron-wrapper.sh curl -s -o /dev/null -f -m 35 \
  -H 'Authorization: Bearer ${CRON_SECRET}' \
  '${BASE_URL}${CRON_ENDPOINT}'" > /var/spool/cron/crontabs/root
crond -f -l 2
