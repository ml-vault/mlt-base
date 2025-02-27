#!/bin/bash

trap cleanup EXIT

LISTEN_PORT=7788
SERVICE_NAME="File Browser"

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    fuser -k -SIGTERM ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n
}

function start() {
    source /opt/ai-dock/filebrowser/filebrowser --port $LISTEN_PORT --address 0.0.0.0 -r /workspace -d /workspace/filebrowser.db
}

start 2>&1
