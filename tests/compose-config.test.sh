#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
rendered_config="$(mktemp)"

cleanup() {
  rm -f "${rendered_config}"
}
trap cleanup EXIT

export CRON_SECRET="test-cron-secret"
export FUNNEL_CRON_SECRET="test-funnel-secret"
export LAUNCHPAD_BASE_URL="https://launchpad.example.test"
export LAUNCHPAD_CRON_SECRET="test-launchpad-secret"
export LAUNCHPAD_NUMBERS_API_KEY="test-launchpad-numbers-key"
export SESSION_SECRET="test-session-secret"
export SLACK_BOT_TOKEN="test-slack-token"

if [[ -n "${COMPOSE_BIN:-}" ]]; then
  compose_command=("${COMPOSE_BIN}")
else
  compose_command=(docker compose)
fi

"${compose_command[@]}" \
  --project-directory "${repo_root}" \
  -f "${repo_root}/docker-compose.yml" \
  config \
  --format json > "${rendered_config}"

expected_services='[
  "athletex-core-bridge",
  "funnel-capi-match",
  "ghl-crm-sync",
  "launchpad-numbers-warm",
  "launchpad-retention-attendance",
  "launchpad-retention-grow",
  "launchpad-retention-roster",
  "mindbody-sync",
  "mindbody-webhook-dispatcher",
  "mindbody-webhook-health",
  "mrr-snapshot",
  "stripe-reconcile",
  "strong-intel-outcome-pull",
  "strong-intro-purchases",
  "wodify-sync"
]'

if ! jq -e \
  --argjson expected "${expected_services}" \
  '(.services | keys | sort) == ($expected | sort)' \
  "${rendered_config}" > /dev/null; then
  echo "Rendered Compose service inventory does not match the expected 15 services." >&2
  exit 1
fi

if ! jq -e '
  .services["mindbody-webhook-dispatcher"] as $service
  | ($service.build.context | endswith("/cron-http"))
    and $service.environment.BASE_URL == "https://lighthouse.mariopaguio.com"
    and $service.environment.CRON_ENDPOINT == "/api/cron/mindbody-webhooks"
    and $service.environment.CRON_NAME == "mindbody-webhook-dispatcher"
    and $service.environment.CRON_SCHEDULE == "* * * * *"
    and $service.environment.CRON_SECRET == "test-cron-secret"
    and $service.environment.SLACK_BOT_TOKEN == "test-slack-token"
    and $service.environment.SLACK_CHANNEL_ID == "C0ALM9P8DQD"
    and $service.restart == "unless-stopped"
' "${rendered_config}" > /dev/null; then
  echo "Rendered dispatcher service does not match its required schedule and endpoint." >&2
  exit 1
fi

if ! jq -e '
  .services["mindbody-webhook-health"] as $service
  | ($service.build.context | endswith("/cron-http"))
    and $service.environment.BASE_URL == "https://lighthouse.mariopaguio.com"
    and $service.environment.CRON_ENDPOINT == "/api/cron/mindbody-webhook-health"
    and $service.environment.CRON_NAME == "mindbody-webhook-health"
    and $service.environment.CRON_SCHEDULE == "12 * * * *"
    and $service.environment.CRON_SECRET == "test-cron-secret"
    and $service.environment.SLACK_BOT_TOKEN == "test-slack-token"
    and $service.environment.SLACK_CHANNEL_ID == "C0ALM9P8DQD"
    and $service.restart == "unless-stopped"
' "${rendered_config}" > /dev/null; then
  echo "Rendered health service does not match its required schedule and endpoint." >&2
  exit 1
fi

echo "Compose config contains all 15 services and the two Mindbody schedules."
