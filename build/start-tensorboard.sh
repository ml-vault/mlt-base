#!/bin/bash

# TensorBoardログディレクトリの確認と作成
LOG_DIR="${TENSORBOARD_LOG_DIR:-/workspace/logs}"
echo "TensorBoard log directory: $LOG_DIR"

# ログディレクトリが存在しない場合は作成
if [ ! -d "$LOG_DIR" ]; then
    echo "Creating log directory: $LOG_DIR"
    mkdir -p "$LOG_DIR"
fi

# ログディレクトリが空の場合はダミーファイルを作成
if [ -z "$(ls -A $LOG_DIR)" ]; then
    echo "Log directory is empty, creating dummy log file"
    echo "TensorBoard dummy log - $(date)" > "$LOG_DIR/dummy.log"
fi

# ディレクトリの権限を確認
chmod -R 755 "$LOG_DIR"

echo "Starting TensorBoard with logdir: $LOG_DIR"
exec tensorboard --logdir="$LOG_DIR" --host=0.0.0.0 --port=6006 --reload_interval=30
