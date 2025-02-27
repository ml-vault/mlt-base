#!/bin/bash

trap cleanup EXIT

LISTEN_PORT=7888
SERVICE_NAME="Infinite Browser"

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    fuser -k -SIGTERM ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n
}

function start() {
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh ibrowser

    printf "Starting %s...\n" ${SERVICE_NAME}
    
    fuser -k -SIGKILL ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n

    cd /opt/ai-dock/infinite-browser && \
    source "$INFINITE_BROWSER_VENV/bin/activate"
    python /opt/ai-dock/infinite-browser/app.py --host 0.0.0.0 --port $LISTEN_PORT
}

start 2>&1
