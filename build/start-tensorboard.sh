#!/bin/bash

# conda環境をアクティベート（フォールバック付き）
echo "Attempting to activate conda environment..."

# condaの初期化
if [ -f "/opt/miniconda/etc/profile.d/conda.sh" ]; then
    source /opt/miniconda/etc/profile.d/conda.sh
    echo "Conda profile sourced"
else
    echo "Warning: Conda profile not found"
fi

# conda環境をアクティベート
if conda info --envs | grep -q "diffusion-pipe"; then
    echo "Activating conda environment: diffusion-pipe"
    conda activate diffusion-pipe
    if [ "$?" -eq 0 ]; then
        echo "Successfully activated conda environment"
    else
        echo "Failed to activate conda environment, using base environment"
        conda activate base
    fi
else
    echo "Warning: diffusion-pipe environment not found, using base environment"
    conda activate base || echo "Failed to activate base environment"
fi

# デバッグ情報を出力
echo "=== TensorBoard Startup Debug ==="
echo "Date: $(date)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Active conda environment: $CONDA_DEFAULT_ENV"
echo "CONDA_PREFIX: $CONDA_PREFIX"
echo "Python path: $(which python)"
echo "Python version: $(python --version 2>/dev/null || echo 'Python not found')"
echo "Python executable: $(python -c 'import sys; print(sys.executable)' 2>/dev/null || echo 'Not found')"
echo "Python sys.path: $(python -c 'import sys; print(sys.path[:3])' 2>/dev/null || echo 'Not found')"
echo "TensorBoard version: $(python -c 'import tensorboard; print(tensorboard.__version__)' 2>/dev/null || echo 'Not found')"
echo "TensorBoard path: $(python -c 'import tensorboard; print(tensorboard.__file__)' 2>/dev/null || echo 'Not found')"

# conda環境の詳細情報
echo "=== Conda Environment Details ==="
conda info --envs || echo "conda info failed"
conda list python || echo "conda list failed"

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

# TensorBoardコマンドの存在確認
if ! command -v tensorboard &> /dev/null; then
    echo "ERROR: tensorboard command not found. Trying with python -m tensorboard..."
    if python -c "import tensorboard" 2>/dev/null; then
        echo "Using python -m tensorboard"
        exec python -m tensorboard.main --logdir="$LOG_DIR" --host=0.0.0.0 --port=6006 2>&1
    else
        echo "ERROR: TensorBoard not available. Exiting."
        exit 127
    fi
else
    echo "Command: tensorboard --logdir=$LOG_DIR --host=0.0.0.0 --port=6006"
    exec tensorboard --logdir="$LOG_DIR" --host=0.0.0.0 --port=6006 2>&1
fi
