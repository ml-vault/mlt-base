[![Docker Build](https://github.com/mlvault/comfyui/actions/workflows/docker-build.yml/badge.svg)](https://github.com/mlvault/comfyui/actions/workflows/docker-build.yml)

# Simple ML Environment Docker Image

シンプルなML開発環境を提供するDockerイメージです。以下のコンポーネントが含まれています：

- **Conda**: Python環境管理
- **Jupyter Lab**: インタラクティブな開発環境
- **Infinite Browser**: ブラウザベースのツール
- **File Browser**: ファイル管理インターフェース
- **TensorBoard**: 機械学習の可視化ツール
- **Python Environment**: 最適化されたPython環境

## 特徴

- AI-Dockの複雑さを排除したシンプルな構成
- 必要最小限のコンポーネントのみを含む
- 軽量で高速な起動
- GPU（NVIDIA CUDA）サポート
- すべてのサービスがSupervisorで管理される

## 使用方法

### Docker Composeを使用

```bash
# リポジトリをクローン
git clone https://github.com/mlvault/comfyui.git
cd comfyui

# イメージをビルドして起動
docker-compose up --build
```

### 直接Dockerを使用

```bash
# イメージをビルド
docker build -t simple-ml ./build

# コンテナを起動
docker run -d \
  --name simple-ml \
  --gpus all \
  -p 8888:8888 \
  -p 6006:6006 \
  -p 8080:8080 \
  -p 8188:8188 \
  -v $(pwd)/workspace:/workspace \
  simple-ml
```

## アクセス可能なサービス

| サービス | ポート | URL | 説明 |
|---------|--------|-----|------|
| Jupyter Lab | 8888 | http://localhost:8888 | インタラクティブな開発環境 |
| TensorBoard | 6006 | http://localhost:6006 | 機械学習の可視化 |
| File Browser | 8080 | http://localhost:8080 | ファイル管理 |
| Infinite Browser | 8188 | http://localhost:8188 | ブラウザベースのツール |

## 環境変数

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `WORKSPACE` | `/workspace` | 作業ディレクトリのパス |
| `JUPYTER_PORT` | `8888` | Jupyter Labのポート |
| `TENSORBOARD_PORT` | `6006` | TensorBoardのポート |
| `FILEBROWSER_PORT` | `8080` | File Browserのポート |
| `INFINITE_BROWSER_PORT` | `8188` | Infinite Browserのポート |
| `TENSORBOARD_LOG_DIR` | `/workspace/logs` | TensorBoardのログディレクトリ |

## ディレクトリ構造

```
/workspace/          # メインの作業ディレクトリ
├── logs/           # TensorBoardログ
└── ...             # あなたのプロジェクトファイル
```

## GPU サポート

NVIDIA GPUを使用する場合は、以下を確認してください：

1. NVIDIA Dockerランタイムがインストールされている
2. `docker-compose.yaml`でGPU設定が有効になっている
3. `--gpus all`フラグを使用してコンテナを起動する

## カスタマイズ

### 追加のPythonパッケージをインストール

```bash
# コンテナ内で
pip install your-package

# または、Dockerfileを編集して永続化
```

### 設定の変更

Supervisorの設定は`/etc/supervisor/conf.d/supervisord.conf`で管理されています。

## トラブルシューティング

### サービスの状態確認

```bash
# コンテナ内で
supervisorctl status
```

### ログの確認

```bash
# 各サービスのログを確認
tail -f /var/log/jupyter.log
tail -f /var/log/tensorboard.log
tail -f /var/log/filebrowser.log
tail -f /var/log/infinite-browser.log
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。

---

_Maintainer: Yoonsoo Kim <laptise@live.jp>_
