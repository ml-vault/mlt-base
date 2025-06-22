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

# Condaの初期化
echo "Initializing conda for bash shell..."
$CONDA_DIR/bin/conda init bash
if [ $? -eq 0 ]; then
    echo "✓ Conda initialized for bash shell."
else
    echo "⚠️  Conda init failed, but continuing..."
fi

# bashrcを読み込んでconda設定を有効化
echo "Loading conda configuration..."
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
    echo "✓ Loaded ~/.bashrc"
elif [ -f /root/.bashrc ]; then
    source /root/.bashrc
    echo "✓ Loaded /root/.bashrc"
else
    echo "⚠️  bashrc not found, setting up conda manually"
    # conda initの内容を手動で設定
    export PATH="$CONDA_DIR/bin:$PATH"
    
    # conda関数を定義
    eval "$($CONDA_DIR/bin/conda shell.bash hook)"
    echo "✓ Conda shell hook initialized"
fi

# condaコマンドが利用可能かチェック
if ! command -v conda &> /dev/null; then
    echo "⚠️  conda command not found in PATH, using direct path"
    export PATH="$CONDA_DIR/bin:$PATH"
    eval "$($CONDA_DIR/bin/conda shell.bash hook)"
fi

echo "✓ Conda initialization completed"

# workspace内のcondaディレクトリを作成（存在しない場合）
echo "Ensuring conda directories exist in workspace..."
mkdir -p /workspace/conda-envs
mkdir -p /workspace/conda-pkgs
chmod 755 /workspace/conda-envs /workspace/conda-pkgs
echo "✓ Conda directories created/verified in workspace."

# conda環境が存在するかチェック
if conda env list | grep -q "^$CONDA_ENV_NAME "; then
    echo "✓ Conda environment '$CONDA_ENV_NAME' already exists."
    
    # 既存環境をアクティベート（sourceコマンドを使用）
    echo "Activating existing conda environment '$CONDA_ENV_NAME'..."
    echo "Debug: Using source command: source $CONDA_DIR/bin/activate $CONDA_ENV_NAME"
    
    # activateスクリプトの存在確認
    if [ -f "$CONDA_DIR/bin/activate" ]; then
        echo "✓ Activate script found at $CONDA_DIR/bin/activate"
    else
        echo "❌ Activate script not found at $CONDA_DIR/bin/activate"
        ls -la "$CONDA_DIR/bin/" | grep activate || echo "No activate scripts found"
    fi
    
    source "$CONDA_DIR/bin/activate" "$CONDA_ENV_NAME"
    ACTIVATE_RESULT=$?
    echo "Debug: Activation result code: $ACTIVATE_RESULT"
    
    if [ $ACTIVATE_RESULT -eq 0 ]; then
        echo "✓ Conda environment '$CONDA_ENV_NAME' activated."
        echo "Debug: Current CONDA_DEFAULT_ENV: ${CONDA_DEFAULT_ENV:-'not set'}"
        echo "Debug: Current PATH: $PATH"
    else
        echo "❌ Failed to activate conda environment."
        echo "Debug: Trying alternative activation method..."
        
        # 代替方法: 環境変数を直接設定
        export CONDA_DEFAULT_ENV="$CONDA_ENV_NAME"
        export CONDA_PREFIX="$CONDA_DIR/envs/$CONDA_ENV_NAME"
        export PATH="$CONDA_PREFIX/bin:$PATH"
        echo "✓ Environment variables set manually."
    fi
    
    # 既存環境でflash-attnがインストールされているかチェック
    echo "Checking if flash-attn is installed in existing environment..."
    if pip list | grep -q "^flash-attn "; then
        echo "✓ flash-attn is already installed."
    else
        echo "Installing flash-attn in existing environment..."
        pip install --no-cache-dir flash-attn --no-build-isolation
        
        if [ $? -eq 0 ]; then
            echo "✓ flash-attn installed successfully."
        else
            echo "⚠️  flash-attn installation failed. This may be due to compilation issues."
            echo "    flash-attn requires CUDA-compatible GPU and may take time to compile."
        fi
    fi
else
    echo "Creating conda environment '$CONDA_ENV_NAME' with Python 3.11..."
    conda create -n "$CONDA_ENV_NAME" python=3.11 -y
    
    if [ $? -eq 0 ]; then
        echo "✓ Conda environment created successfully."
        
        # conda環境をアクティベート（sourceコマンドを使用）
        echo "Activating conda environment '$CONDA_ENV_NAME'..."
        echo "Debug: Using source command: source $CONDA_DIR/bin/activate $CONDA_ENV_NAME"
        
        # activateスクリプトの存在確認
        if [ -f "$CONDA_DIR/bin/activate" ]; then
            echo "✓ Activate script found at $CONDA_DIR/bin/activate"
        else
            echo "❌ Activate script not found at $CONDA_DIR/bin/activate"
            ls -la "$CONDA_DIR/bin/" | grep activate || echo "No activate scripts found"
        fi
        
        source "$CONDA_DIR/bin/activate" "$CONDA_ENV_NAME"
        ACTIVATE_RESULT=$?
        echo "Debug: Activation result code: $ACTIVATE_RESULT"
        
        if [ $ACTIVATE_RESULT -eq 0 ]; then
            echo "✓ Conda environment '$CONDA_ENV_NAME' activated."
            echo "Debug: Current CONDA_DEFAULT_ENV: ${CONDA_DEFAULT_ENV:-'not set'}"
            echo "Debug: Current PATH: $PATH"
        else
            echo "❌ Failed to activate conda environment."
            echo "Debug: Trying alternative activation method..."
            
            # 代替方法: 環境変数を直接設定
            export CONDA_DEFAULT_ENV="$CONDA_ENV_NAME"
            export CONDA_PREFIX="$CONDA_DIR/envs/$CONDA_ENV_NAME"
            export PATH="$CONDA_PREFIX/bin:$PATH"
            echo "✓ Environment variables set manually."
        fi
        
        # 必要なパッケージをインストール
        echo "Installing packages in '$CONDA_ENV_NAME' environment..."
        
        pip install --no-cache-dir \
            jupyter \
            jupyterlab \
            notebook \
            matplotlib \
            seaborn \
            pandas \
            scikit-learn \
            plotly \
            tensorboard
        
        # flash-attnのインストール（GPU環境用）
        echo "Installing flash-attn for GPU acceleration..."
        pip install --no-cache-dir flash-attn --no-build-isolation
        
        if [ $? -eq 0 ]; then
            echo "✓ flash-attn installed successfully."
        else
            echo "⚠️  flash-attn installation failed. This may be due to compilation issues."
            echo "    flash-attn requires CUDA-compatible GPU and may take time to compile."
        fi
            
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

# 設定ファイルの構文チェック（テストモードで実行）
echo "Validating Supervisor configuration..."
# -tオプションは設定テストのみで実際の起動は行わない
if /usr/bin/supervisord -c "$SUPERVISOR_CONFIG" -t 2>/dev/null; then
    echo "✓ Supervisor configuration is valid."
else
    echo "❌ Supervisor configuration has errors!"
    echo "Debug: Configuration file content:"
    cat "$SUPERVISOR_CONFIG"
    exit 1
fi

# 必要なコマンドの存在確認
echo "Checking required commands..."
for cmd in supervisord supervisorctl; do
    if command -v $cmd >/dev/null 2>&1; then
        echo "✓ $cmd found: $(which $cmd)"
    else
        echo "❌ $cmd not found!"
        exit 1
    fi
done

# =============================================================================
# 3. Supervisorの起動
# =============================================================================
echo ""
echo "=== Step 3: Starting Supervisor ==="

# 既存のsupervisordプロセスとソケットファイルをクリーンアップ
echo "Cleaning up any existing Supervisor processes and files..."
if pgrep -f supervisord > /dev/null; then
    echo "⚠️  Supervisor is already running. Stopping existing process..."
    pkill -f supervisord || true
    sleep 3
fi

# ソケットファイルとPIDファイルをクリーンアップ
rm -f /var/run/supervisor.sock /var/run/supervisord.pid
echo "✓ Cleaned up existing Supervisor files."

# 必要なディレクトリとファイルの準備
echo "Preparing directories and files for Supervisor..."
mkdir -p /var/run /var/log /workspace
touch /var/log/supervisord.log
chmod 755 /var/run /var/log
chmod 644 /var/log/supervisord.log

# 権限確認
echo "Debug: Directory permissions:"
ls -la /var/run/ | head -5
ls -la /var/log/ | head -5

# Supervisorをフォアグラウンドで起動（nodaemon=true設定のため）
echo "Starting Supervisor daemon in foreground mode..."
echo "Debug: Supervisor command: /usr/bin/supervisord -c $SUPERVISOR_CONFIG"

# Supervisorを起動し、出力をキャプチャ
echo "Debug: Starting supervisord with detailed output..."
/usr/bin/supervisord -c "$SUPERVISOR_CONFIG" 2>&1 &
SUPERVISOR_PID=$!

echo "Debug: Supervisor started with PID: $SUPERVISOR_PID"

# Supervisorの起動を待機
echo "Waiting for Supervisor to start..."
sleep 5

# プロセスが実際に動いているか確認
if kill -0 $SUPERVISOR_PID 2>/dev/null; then
    echo "✓ Supervisor process is running (PID: $SUPERVISOR_PID)"
else
    echo "❌ Supervisor process is not running!"
    echo ""
    echo "=== SUPERVISOR STARTUP FAILURE DEBUG ==="
    echo "1. Process check:"
    ps aux | grep supervisord | grep -v grep || echo "No supervisord processes found"
    echo ""
    echo "2. Supervisor log (last 30 lines):"
    tail -30 /var/log/supervisord.log 2>/dev/null || echo "No supervisor log found"
    echo ""
    echo "3. System error log:"
    dmesg | tail -10 | grep -i error || echo "No recent system errors"
    echo ""
    echo "4. File permissions:"
    ls -la /var/run/supervisor* 2>/dev/null || echo "No supervisor files in /var/run"
    ls -la /var/log/supervisor* 2>/dev/null || echo "No supervisor files in /var/log"
    echo ""
    echo "5. Disk space:"
    df -h /var /tmp
    echo ""
    echo "6. Memory usage:"
    free -h
    echo ""
    echo "7. Manual supervisor test:"
    echo "Attempting to start supervisord manually..."
    /usr/bin/supervisord -c "$SUPERVISOR_CONFIG" -n 2>&1 | head -20 &
    MANUAL_PID=$!
    sleep 2
    kill $MANUAL_PID 2>/dev/null || true
    echo "=== END DEBUG ==="
    exit 1
fi

# supervisorctlが利用可能になるまで待機
echo "Waiting for supervisorctl to be available..."
echo "Debug: Initial supervisor process check..."
ps aux | grep supervisord | grep -v grep

echo "Debug: Checking supervisor socket and config..."
ls -la /var/run/supervisor.sock 2>/dev/null || echo "Socket file not found at /var/run/supervisor.sock"
ls -la /tmp/supervisor.sock 2>/dev/null || echo "Socket file not found at /tmp/supervisor.sock"
echo "Config file: $SUPERVISOR_CONFIG"
cat "$SUPERVISOR_CONFIG" | head -20

for i in {1..30}; do
    echo "Attempt $i/30: Testing supervisorctl connection..."
    
    # より詳細なデバッグ出力
    echo "  - Supervisor process status:"
    ps aux | grep supervisord | grep -v grep || echo "    No supervisord process found"
    
    echo "  - Socket file check:"
    ls -la /var/run/supervisor.sock 2>/dev/null || echo "    /var/run/supervisor.sock not found"
    ls -la /tmp/supervisor.sock 2>/dev/null || echo "    /tmp/supervisor.sock not found"
    
    echo "  - Testing supervisorctl status command:"
    supervisorctl -c "$SUPERVISOR_CONFIG" status 2>&1 | head -5
    
    if supervisorctl -c "$SUPERVISOR_CONFIG" status > /dev/null 2>&1; then
        echo "✓ supervisorctl is ready."
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ supervisorctl is not available after 30 seconds."
        echo ""
        echo "=== FINAL DEBUG INFORMATION ==="
        echo "1. Supervisor processes:"
        ps aux | grep supervisord
        echo ""
        echo "2. Socket files:"
        find /var/run /tmp -name "*supervisor*" 2>/dev/null || echo "No supervisor socket files found"
        echo ""
        echo "3. Supervisor config:"
        cat "$SUPERVISOR_CONFIG"
        echo ""
        echo "4. Supervisor logs:"
        tail -20 /var/log/supervisord.log 2>/dev/null || echo "No supervisor log found"
        echo ""
        echo "5. System logs:"
        dmesg | tail -10
        echo ""
        echo "6. Network and ports:"
        netstat -tlnp | grep -E "(9001|supervisor)" || echo "No supervisor ports found"
    fi
    
    sleep 1
done

# =============================================================================
# 4. サービスの段階的起動
# =============================================================================
echo ""
echo "=== Step 4: Starting Services ==="

# conda環境が正常に作成されているかチェック
if conda env list | grep -q "$CONDA_ENV_NAME"; then
    echo "✓ Conda environment '$CONDA_ENV_NAME' verified. Starting all services..."
    
    # すべてのサービスを一括起動
    echo "Starting all services..."
    supervisorctl -c "$SUPERVISOR_CONFIG" start all
    
    # 個別サービスの起動状況を確認
    sleep 3
    echo ""
    echo "Checking individual service status:"
    
    # Jupyter Lab の状態確認
    if supervisorctl -c "$SUPERVISOR_CONFIG" status jupyter | grep -q "RUNNING"; then
        echo "✓ Jupyter Lab is running."
    else
        echo "⚠️  Jupyter Lab failed to start. Attempting manual start..."
        supervisorctl -c "$SUPERVISOR_CONFIG" start jupyter
    fi
    
    # TensorBoard の状態確認（環境変数でオンの場合）
    if [ "${TENSORBOARD_AUTOSTART:-true}" = "true" ]; then
        if supervisorctl -c "$SUPERVISOR_CONFIG" status tensorboard | grep -q "RUNNING"; then
            echo "✓ TensorBoard is running."
        else
            echo "⚠️  TensorBoard failed to start. Attempting manual start..."
            supervisorctl -c "$SUPERVISOR_CONFIG" start tensorboard
        fi
    else
        echo "⏭️  TensorBoard autostart is disabled."
    fi
    
    # Infinite Browser の状態確認
    if supervisorctl -c "$SUPERVISOR_CONFIG" status infinite-browser | grep -q "RUNNING"; then
        echo "✓ Infinite Browser is running."
    else
        echo "⚠️  Infinite Browser failed to start. Attempting manual start..."
        supervisorctl -c "$SUPERVISOR_CONFIG" start infinite-browser
    fi
    
    # File Browser の状態確認（autostartがtrueなので既に起動しているはず）
    if supervisorctl -c "$SUPERVISOR_CONFIG" status filebrowser | grep -q "RUNNING"; then
        echo "✓ File Browser is running."
    else
        echo "⚠️  File Browser failed to start. This is unexpected since autostart=true."
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
supervisorctl -c "$SUPERVISOR_CONFIG" status
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
    supervisorctl -c "$SUPERVISOR_CONFIG" stop all
    supervisorctl -c "$SUPERVISOR_CONFIG" shutdown
    echo "✓ All services stopped."
    exit 0
}

trap cleanup SIGTERM SIGINT

# フォアグラウンドで実行継続
wait $SUPERVISOR_PID
