# RunPod PyTorchベースイメージを使用
FROM runpod/pytorch:2.8.0-py3.11-cuda12.8.1-cudnn-devel-ubuntu22.04

LABEL org.opencontainers.image.source https://github.com/mlvault/comfyui
LABEL org.opencontainers.image.description "Simple ML environment with conda, jupyter, infinite-browser, filebrowser, tensorboard"
LABEL maintainer="Yoonsoo Kim <laptise@live.jp>"

# 基本パッケージのインストール
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    git \
    build-essential \
    cmake \
    pkg-config \
    supervisor \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Minicondaのインストール（既存のcondaがある場合はスキップ）
ENV CONDA_DIR=/opt/miniconda
ENV PATH=$CONDA_DIR/bin:$PATH
RUN if [ ! -d "$CONDA_DIR" ]; then \
        wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
        bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
        rm /tmp/miniconda.sh && \
        conda clean -afy; \
    fi

# diffusion-pipe conda環境の作成
RUN conda create -n diffusion-pipe python=3.12 -y && \
    conda clean -afy

# diffusion-pipe環境に必要なパッケージをインストール
RUN /bin/bash -c "source $CONDA_DIR/bin/activate diffusion-pipe && \
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
        tensorflow-tensorboard-plugin-wit"

# File Browserのインストール
RUN filemanager_os="linux" && \
    filemanager_arch="amd64" && \
    filemanager_file="${filemanager_os}-${filemanager_arch}-filebrowser.tar.gz" && \
    filemanager_tag="$(curl -fsSL https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"//g' | sed 's/tag_name: //g')" && \
    filemanager_url="https://github.com/filebrowser/filebrowser/releases/download/${filemanager_tag}/${filemanager_file}" && \
    curl -fsSL "${filemanager_url}" > "/tmp/${filemanager_file}" && \
    tar -xzf "/tmp/${filemanager_file}" -C "/tmp/" "filebrowser" && \
    chmod +x "/tmp/filebrowser" && \
    mv "/tmp/filebrowser" "/usr/local/bin/filebrowser" && \
    rm "/tmp/${filemanager_file}"

# diffusion-pipe環境をデフォルトに設定
ENV CONDA_DEFAULT_ENV=diffusion-pipe
ENV PATH=$CONDA_DIR/envs/diffusion-pipe/bin:$PATH

# Infinite Image Browsing のインストール
RUN git clone https://github.com/ml-vault/sd-webui-infinite-image-browsing.git /opt/infinite-browser && \
    cd /opt/infinite-browser && \
    /bin/bash -c "source $CONDA_DIR/bin/activate diffusion-pipe && pip install --no-cache-dir -r requirements.txt"

# 作業ディレクトリの設定
WORKDIR /workspace

# ポートの公開
EXPOSE 8888 6006 8080 8188

# Supervisorの設定ディレクトリ作成
RUN mkdir -p /etc/supervisor/conf.d

# Supervisorの設定ファイルとTensorBoard起動スクリプトをコピー
COPY supervisord.ini /etc/supervisor/conf.d/supervisord.ini
COPY start-tensorboard.sh /usr/local/bin/start-tensorboard.sh
RUN chmod +x /usr/local/bin/start-tensorboard.sh

# 環境変数の設定
ENV WORKSPACE=/workspace
ENV JUPYTER_PORT=8888
ENV TENSORBOARD_PORT=6006
ENV FILEBROWSER_PORT=8080
ENV INFINITE_BROWSER_PORT=8188
ENV TENSORBOARD_AUTOSTART=true

# ワークスペースディレクトリの作成とTensorBoard用ダミーログファイルの作成
RUN mkdir -p /workspace/logs && \
    echo "TensorBoard dummy log file - $(date)" > /workspace/logs/dummy.log && \
    chmod -R 755 /workspace/logs

# 起動コマンド
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.ini"]
