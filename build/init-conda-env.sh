#!/bin/bash

# conda環境初期化スクリプト
CONDA_ENV_NAME="diffusion-pipe"
CONDA_DIR="/opt/miniconda"

echo "=== Conda Environment Initialization ==="
echo "Date: $(date)"
echo "Environment: $CONDA_ENV_NAME"

# workspace内のcondaディレクトリを作成（存在しない場合）
echo "Ensuring conda directories exist in workspace..."
mkdir -p /workspace/conda-envs
mkdir -p /workspace/conda-pkgs
chmod 755 /workspace/conda-envs /workspace/conda-pkgs
echo "Conda directories created/verified in workspace."

# conda環境が存在するかチェック
if conda env list | grep -q "^$CONDA_ENV_NAME "; then
    echo "Conda environment '$CONDA_ENV_NAME' already exists."
else
    echo "Creating conda environment '$CONDA_ENV_NAME' with Python 3.12..."
    conda create -n "$CONDA_ENV_NAME" python=3.12 -y
    
    if [ $? -eq 0 ]; then
        echo "Conda environment created successfully."
        
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
        
        echo "Package installation completed."
    else
        echo "Failed to create conda environment."
        exit 1
    fi
fi

echo "Conda environment initialization completed."
