#!/usr/bin/env bash

set -e

# if `HOST_IP` is manually configured as env
HOST="$HOST_IP"

if [[ -z "$HOST" ]]; then
  HOST=$(getent hosts host.docker.internal | awk '{ print $1 }')
fi

if [[ -z "$HOST" ]]; then
  HOST=$(ip route | awk 'NR==1 {print $3}')
fi

if [[ -f $XDEBUG_CONF_FILE ]]; then
  sed -i "s/xdebug\.client_host=.*/xdebug\.client_host=${HOST}/" $XDEBUG_CONF_FILE
fi
