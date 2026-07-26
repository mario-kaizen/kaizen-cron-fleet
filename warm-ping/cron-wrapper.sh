#!/bin/bash
set -euo pipefail
CRON_NAME="${CRON_NAME:-unknown-cron}"
SLACK_CHANNEL_ID="${SLACK_CHANNEL_ID:-C0ALM9P8DQD}"
SLACK_BOT_TOKEN="${SLACK_BOT_TOKEN:-}"
LOG_FILE="/tmp/cron-${CRON_NAME}-$(date +%Y%m%d-%H%M%S).log"
echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Starting: ${CRON_NAME}" | tee "${LOG_FILE}"
if "$@" >> "${LOG_FILE}" 2>&1; then
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Success: ${CRON_NAME}" | tee -a "${LOG_FILE}"
  exit 0
else
  EXIT_CODE=$?
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] FAILED: ${CRON_NAME} (exit code ${EXIT_CODE})" | tee -a "${LOG_FILE}"
  if [ -n "${SLACK_BOT_TOKEN}" ]; then
    LAST_LINES=$(tail -20 "${LOG_FILE}" | jq -Rs .)
    curl -s -X POST "https://slack.com/api/chat.postMessage" \
      -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "{
        \"channel\": \"${SLACK_CHANNEL_ID}\",
        \"text\": \":rotating_light: Cron failed: *${CRON_NAME}*\",
        \"blocks\": [
          {
            \"type\": \"section\",
            \"text\": {
              \"type\": \"mrkdwn\",
              \"text\": \":rotating_light: *Cron Failed: ${CRON_NAME}*\nExit code: ${EXIT_CODE}\nTime: $(date -u +%Y-%m-%dT%H:%M:%SZ)\n\`\`\`\n${LAST_LINES}\n\`\`\`\"
            }
          }
        ]
      }" > /dev/null
  fi
  exit "${EXIT_CODE}"
fi
