#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Render with synthetic credentials only; never print a deployed crontab.
export CRON_SECRET=test SESSION_SECRET=test SLACK_BOT_TOKEN=test
export FUNNEL_CRON_SECRET=test LAUNCHPAD_BASE_URL=https://example.test
export LAUNCHPAD_CRON_SECRET=test LAUNCHPAD_NUMBERS_API_KEY=test
docker compose -f "$repo_root/docker-compose.yml" config --format json | jq -e '
 .services["winning-creatives"] as $s |
 $s.environment.CRON_SCHEDULE == "0 7 * * 1" and
 $s.environment.TZ == "Australia/Sydney" and
 $s.environment.CRON_ENDPOINT == "/api/cron/winning-creatives" and
 ($s.entrypoint[2] | contains("unset SLACK_BOT_TOKEN SLACK_CHANNEL_ID")) and
 ([.services | to_entries[] | select(.key != "winning-creatives" and .key != "paid-media-briefing") | .value.environment.TZ // empty] | length == 0)
' >/dev/null
docker compose -f "$repo_root/docker-compose.yml" config --format json | jq -e '
 .services["paid-media-briefing"] as $s |
 $s.environment.CRON_SCHEDULE == "30 23 * * *" and
 $s.environment.TZ == "Australia/Sydney" and
 $s.environment.CRON_ENDPOINT == "/api/cron/paid-media-briefing"
' >/dev/null
printf 'Winning Creatives collects Monday 7am Sydney; Paid Media briefs nightly 11:30pm Sydney; other service timezones unchanged.\n'
