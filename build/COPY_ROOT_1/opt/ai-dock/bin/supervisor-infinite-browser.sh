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
    source /opt/ai-dock/bin/venv-set.sh infinite-browser

    printf "Starting %s...\n" ${SERVICE_NAME}
    
    fuser -k -SIGKILL ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n

    cd /opt/ai-dock/infinite-browser && \
    source "$INFINITE_BROWSER_VENV/bin/activate"
    uvicorn main:app \
        --host 127.0.0.1 \
        --port $LISTEN_PORT \
        --reload
}

start 2>&1
