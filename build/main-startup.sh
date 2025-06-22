#!/bin/bash

# =============================================================================
# メイン起動スクリプト - Conda環境初期化とSupervisor起動を統合
# =============================================================================

set -e  # エラー時に停止

CONDA_ENV_NAME="diffusion-pipe"
CONDA_DIR="/opt/miniconda"
SUPERVISOR_CONFIG="/etc/supervisor/conf.d/supervisord.ini"

echo "=============================================="
echo "=== ComfyUI Environment Startup Script ==="
echo "=============================================="
echo "Date: $(date)"
echo "Environment: $CONDA_ENV_NAME"
echo "Conda Directory: $CONDA_DIR"
echo "=============================================="

# =============================================================================
# 1. Conda環境の初期化
# =============================================================================
echo ""
echo "=== Step 1: Conda Environment Initialization ==="

# workspace内のcondaディレクトリを作成（存在しない場合）
echo "Ensuring conda directories exist in workspace..."
mkdir -p /workspace/conda-envs
mkdir -p /workspace/conda-pkgs
chmod 755 /workspace/conda-envs /workspace/conda-pkgs
echo "✓ Conda directories created/verified in workspace."

# conda環境が存在するかチェック
if conda env list | grep -q "^$CONDA_ENV_NAME "; then
    echo "✓ Conda environment '$CONDA_ENV_NAME' already exists."
else
    echo "Creating conda environment '$CONDA_ENV_NAME' with Python 3.11..."
    conda create -n "$CONDA_ENV_NAME" python=3.11 -y
    
    if [ $? -eq 0 ]; then
        echo "✓ Conda environment created successfully."
        
        # 必要なパッケージをインストール
        echo "Installing packages in '$CONDA_ENV_NAME' environment..."
        source "$CONDA_DIR/bin/activate" "$CONDA_ENV_NAME"
        
        pip install --no-cache-dir \
            jupyter \
            jupyterlab \
            notebook \
            matplotlib \
            seaborn \
            pandas \
            scikit-learn \
            plotly \
            tensorboard \
            tensorflow-tensorboard-plugin-wit
            
        # Infinite Browser の依存関係もインストール
        if [ -f "/opt/infinite-browser/requirements.txt" ]; then
            echo "Installing infinite-browser requirements..."
            pip install --no-cache-dir -r /opt/infinite-browser/requirements.txt
        fi
        
        echo "✓ Package installation completed."
    else
        echo "❌ Failed to create conda environment."
        exit 1
    fi
fi

echo "✓ Conda environment initialization completed."

# =============================================================================
# 2. Supervisor設定の動的更新
# =============================================================================
echo ""
echo "=== Step 2: Supervisor Configuration Update ==="

# supervisord設定ファイルが存在するかチェック
if [ ! -f "$SUPERVISOR_CONFIG" ]; then
    echo "❌ Supervisor configuration file not found: $SUPERVISOR_CONFIG"
    exit 1
fi

echo "✓ Supervisor configuration file found."

# =============================================================================
# 3. Supervisorの起動
# =============================================================================
echo ""
echo "=== Step 3: Starting Supervisor ==="

# 既存のsupervisordプロセスをチェック
if pgrep -f supervisord > /dev/null; then
    echo "⚠️  Supervisor is already running. Stopping existing process..."
    pkill -f supervisord || true
    sleep 2
fi

# Supervisorを起動
echo "Starting Supervisor daemon..."
/usr/bin/supervisord -c "$SUPERVISOR_CONFIG" &
SUPERVISOR_PID=$!

# Supervisorの起動を待機
echo "Waiting for Supervisor to start..."
sleep 5

# Supervisorが正常に起動したかチェック
if ! pgrep -f supervisord > /dev/null; then
    echo "❌ Failed to start Supervisor daemon."
    exit 1
fi

echo "✓ Supervisor daemon started successfully."

# =============================================================================
# 4. サービスの段階的起動
# =============================================================================
echo ""
echo "=== Step 4: Starting Services ==="

# supervisorctlが利用可能になるまで待機
echo "Waiting for supervisorctl to be available..."
for i in {1..30}; do
    if supervisorctl status > /dev/null 2>&1; then
        echo "✓ supervisorctl is ready."
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ supervisorctl is not available after 30 seconds."
        exit 1
    fi
    sleep 1
done

# conda環境が正常に作成されているかチェック
if conda env list | grep -q "$CONDA_ENV_NAME"; then
    echo "✓ Conda environment '$CONDA_ENV_NAME' verified. Starting services..."
    
    # Jupyter Lab を起動
    echo "Starting Jupyter Lab..."
    supervisorctl start jupyter
    if [ $? -eq 0 ]; then
        echo "✓ Jupyter Lab started successfully."
    else
        echo "⚠️  Failed to start Jupyter Lab."
    fi
    
    # TensorBoard を起動（環境変数でオンの場合）
    if [ "${TENSORBOARD_AUTOSTART:-true}" = "true" ]; then
        echo "Starting TensorBoard..."
        supervisorctl start tensorboard
        if [ $? -eq 0 ]; then
            echo "✓ TensorBoard started successfully."
        else
            echo "⚠️  Failed to start TensorBoard."
        fi
    else
        echo "⏭️  TensorBoard autostart is disabled."
    fi
    
    # Infinite Browser を起動
    echo "Starting Infinite Browser..."
    supervisorctl start infinite-browser
    if [ $? -eq 0 ]; then
        echo "✓ Infinite Browser started successfully."
    else
        echo "⚠️  Failed to start Infinite Browser."
    fi
    
else
    echo "❌ Conda environment '$CONDA_ENV_NAME' not found!"
    exit 1
fi

# =============================================================================
# 5. 起動完了とステータス表示
# =============================================================================
echo ""
echo "=============================================="
echo "=== Startup Complete ==="
echo "=============================================="
echo "Date: $(date)"
echo ""
echo "Service Status:"
supervisorctl status
echo ""
echo "Available Services:"
echo "  - Jupyter Lab:      http://localhost:8888"
echo "  - TensorBoard:      http://localhost:6006"
echo "  - File Browser:     http://localhost:8080"
echo "  - Infinite Browser: http://localhost:8188"
echo ""
echo "Logs are available at:"
echo "  - Supervisor:       /var/log/supervisord.log"
echo "  - Jupyter:          /var/log/jupyter.log"
echo "  - TensorBoard:      /var/log/tensorboard.log"
echo "  - File Browser:     /var/log/filebrowser.log"
echo "  - Infinite Browser: /var/log/infinite-browser.log"
echo "=============================================="

# =============================================================================
# 6. フォアグラウンドで実行継続
# =============================================================================
echo ""
echo "=== Keeping container running ==="
echo "Press Ctrl+C to stop all services and exit."

# シグナルハンドラーを設定
cleanup() {
    echo ""
    echo "=== Shutting down services ==="
    supervisorctl stop all
    supervisorctl shutdown
    echo "✓ All services stopped."
    exit 0
}

trap cleanup SIGTERM SIGINT

# フォアグラウンドで実行継続
wait $SUPERVISOR_PID
