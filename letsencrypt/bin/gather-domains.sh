#!/bin/bash

find /servers -maxdepth 1 -type d|tail -n+2|while read d; do
  find "$d" -type f -print0|xargs -0 grep -wh '^\s*server_name\b'|grep -v '.well-known/acme-challenge'|sed 's@.*://@@;s/;.*//'|grep -o '\w[._[:alnum:]]*'|grep -v '^\(_\|localhost\|server_name\)$'|sort -u|paste -sd,|grep -v ^$
done
