#!/bin/bash

# デバッグ情報を出力
echo "=== TensorBoard Startup Debug ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Python version: $(python --version)"
echo "TensorBoard version: $(python -c 'import tensorboard; print(tensorboard.__version__)' 2>/dev/null || echo 'Not found')"

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

# ディレクトリの内容を確認
echo "Log directory contents:"
ls -la "$LOG_DIR"

# TensorBoardのインストール確認
echo "Checking TensorBoard installation:"
which tensorboard || echo "tensorboard command not found in PATH"
python -c "import tensorboard; print('TensorBoard import successful')" || echo "TensorBoard import failed"

# 環境変数を表示
echo "Environment variables:"
env | grep -E "(TENSOR|LOG|WORKSPACE)" || echo "No relevant environment variables found"

echo "Starting TensorBoard with logdir: $LOG_DIR"

# 最初に基本的なTensorBoardコマンドを試す
echo "Attempting basic TensorBoard startup..."
echo "Command: tensorboard --logdir=$LOG_DIR --host=0.0.0.0 --port=6006"

# TensorBoardを起動（最小限のオプションで）
exec tensorboard --logdir="$LOG_DIR" --host=0.0.0.0 --port=6006 2>&1
