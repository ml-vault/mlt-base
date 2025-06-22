#!/bin/bash

# サービス起動スクリプト
echo "=== Starting Services After Conda Init ==="
echo "Date: $(date)"

# conda環境が正常に作成されているかチェック
if conda env list | grep -q "diffusion-pipe"; then
    echo "Conda environment 'diffusion-pipe' found. Starting services..."
    
    # Jupyter Lab を起動
    echo "Starting Jupyter Lab..."
    supervisorctl start jupyter
    
    # TensorBoard を起動（環境変数でオンの場合）
    if [ "${TENSORBOARD_AUTOSTART:-true}" = "true" ]; then
        echo "Starting TensorBoard..."
        supervisorctl start tensorboard
    fi
    
    # Infinite Browser を起動
    echo "Starting Infinite Browser..."
    supervisorctl start infinite-browser
    
    echo "All services started successfully."
else
    echo "ERROR: Conda environment 'diffusion-pipe' not found!"
    exit 1
fi
