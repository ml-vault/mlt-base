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

# 必要なPythonパッケージのインストール（PyTorchは既にインストール済み）
RUN pip install --no-cache-dir \
    jupyter \
    jupyterlab \
    tensorboard \
    notebook

# File Browserのインストール
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# Infinite Browserのインストール
RUN pip install --no-cache-dir infinite-browser

# 作業ディレクトリの設定
WORKDIR /workspace

# ポートの公開
EXPOSE 8888 6006 8080 8188

# Supervisorの設定ディレクトリ作成
RUN mkdir -p /etc/supervisor/conf.d

# Supervisorの設定ファイル
RUN echo '[supervisord]\n\
nodaemon=true\n\
user=root\n\
\n\
[program:jupyter]\n\
command=jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --ServerApp.token="" --ServerApp.password="" --ServerApp.allow_origin="*"\n\
directory=/workspace\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/jupyter.log\n\
stderr_logfile=/var/log/jupyter.log\n\
\n\
[program:tensorboard]\n\
command=tensorboard --logdir=/workspace/logs --host=0.0.0.0 --port=6006\n\
directory=/workspace\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/tensorboard.log\n\
stderr_logfile=/var/log/tensorboard.log\n\
\n\
[program:filebrowser]\n\
command=filebrowser -a 0.0.0.0 -p 8080 -r /workspace\n\
directory=/workspace\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/filebrowser.log\n\
stderr_logfile=/var/log/filebrowser.log\n\
\n\
[program:infinite-browser]\n\
command=infinite-browser --host=0.0.0.0 --port=8188\n\
directory=/workspace\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/var/log/infinite-browser.log\n\
stderr_logfile=/var/log/infinite-browser.log\n\
' > /etc/supervisor/conf.d/supervisord.conf

# 環境変数の設定
ENV WORKSPACE=/workspace
ENV JUPYTER_PORT=8888
ENV TENSORBOARD_PORT=6006
ENV FILEBROWSER_PORT=8080
ENV INFINITE_BROWSER_PORT=8188

# ワークスペースディレクトリの作成
RUN mkdir -p /workspace/logs

# 起動コマンド
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
