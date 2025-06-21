#!/bin/bash

trap cleanup EXIT

LISTEN_PORT=${TENSORBOARD_PORT_HOST:-6006}
TENSORBOARD_LOG_DIR=${TENSORBOARD_LOG_DIR:-/workspace/logs}
SERVICE_NAME="TensorBoard"

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    fuser -k -SIGTERM ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n
}

function start() {
    # TensorBoardのログディレクトリを作成（存在しない場合）
    mkdir -p "${TENSORBOARD_LOG_DIR}"
    
    # ComfyUI仮想環境のTensorBoardを使用
    ${COMFYUI_VENV_PYTHON} -m tensorboard.main --logdir="${TENSORBOARD_LOG_DIR}" --host=0.0.0.0 --port=${LISTEN_PORT}
}

start 2>&1
