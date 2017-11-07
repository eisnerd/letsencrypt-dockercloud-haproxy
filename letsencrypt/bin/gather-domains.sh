#!/bin/bash

scrape_nginx() {
  find . -type f -print0|
    xargs -0 grep -wh '^\s*server_name\b'|
    grep -v '.well-known/acme-challenge'|
    sed 's@.*://\|;.*\|\wlocalhost\w\|server_name _\?\|^[[:space:]]*@@g'|
    sed 's/^\*\.\(.*\)/www.\1\n\1/'
}

find /servers -maxdepth 1 -type d|tail -n+2|while read d; do
  (
    cd "$d"
    scrape_nginx
  )|sort -u|grep -v '^\s*$'|paste -sd,|grep -v ^$
done

exit 0
