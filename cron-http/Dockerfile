FROM alpine:3.19
RUN apk add --no-cache curl bash jq
ENV CRON_NAME="" CRON_SCHEDULE="" CRON_ENDPOINT="" CRON_SECRET="" SESSION_SECRET="" BASE_URL="https://lighthouse.mariopaguio.com" SLACK_BOT_TOKEN="" SLACK_CHANNEL_ID="C0ALM9P8DQD"
COPY entrypoint.sh /entrypoint.sh
COPY cron-wrapper.sh /usr/local/bin/cron-wrapper.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/cron-wrapper.sh
ENTRYPOINT ["/entrypoint.sh"]
