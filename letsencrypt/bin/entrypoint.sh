#!/bin/bash

# Validate required environment variables.
[[ -z "$EMAIL" ]] && MISSING="$MISSING EMAIL"
if [[ -n "$MISSING" ]]; then
	echo "Missing required environment variables: $MISSING" >&2
	exit 1
fi

# Wait for HAproxy to start before updating certificates on startup.
# TODO: Use Dockerize, instead of assuming it takes 60 seconds to start.

mkdir -p /servers

gather-domains.sh > domains

(
  sleep 15
  update-certs.sh
  max_starvation=60
  rm -f starved_since
  inotifywait -mqre modify /servers | while read EV; do
    starved_since="$(stat -c %Y starved_since 2> /dev/null)"
    if [ -n "$starved_since" ]; then
      [ $(($(date +%s) - $starved_since)) -gt $max_starvation ] &&
        while [ -e starved_since ]; do echo waiting; sleep 1; done
    else
      touch starved_since
    fi
    jobs -p | xargs kill -9 2> /dev/null
    (
      rm -f starved_since
      new=$(mktemp)
      gather-domains.sh > $new
      mv $new domains.new && ! cmp domains domains.new && mv -v domains.new domains 2> /dev/null && cat -n domains >&2 && update-certs.sh
    ) &
  done
) &

exec "$@"
