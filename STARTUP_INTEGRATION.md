# 起動スクリプト統合ドキュメント

## 概要

ComfyUI環境の起動プロセスを統合し、conda環境の初期化からsupervisorの起動まで全てを1つのメインスクリプトで管理するように改善しました。

## 変更内容

### 1. 新しいメイン起動スクリプト

**ファイル**: [`build/main-startup.sh`](build/main-startup.sh:1)

このスクリプトは以下の処理を順次実行します：

1. **Conda環境の初期化**
   - workspace内のcondaディレクトリ作成
   - `diffusion-pipe`環境の作成（存在しない場合）
   - 必要なPythonパッケージのインストール

2. **Supervisor設定の確認**
   - 設定ファイルの存在確認

3. **Supervisorの起動**
   - 既存プロセスのクリーンアップ
   - Supervisorデーモンの起動

4. **サービスの段階的起動**
   - Jupyter Lab
   - TensorBoard（環境変数で制御）
   - Infinite Browser

5. **ステータス表示とフォアグラウンド実行**
   - 各サービスの状態表示
   - シグナルハンドリングによる適切な終了処理

### 2. Supervisor設定の簡素化

**ファイル**: [`build/supervisord.ini`](build/supervisord.ini:1)

- `conda-init`プログラムを削除（メインスクリプトに統合）
- `service-starter`プログラムを削除（メインスクリプトに統合）
- 各サービスは`autostart=false`に設定し、メインスクリプトから制御

### 3. Dockerfileの更新

**ファイル**: [`build/Dockerfile`](build/Dockerfile:1)

- 新しいメイン起動スクリプトをコピー
- 実行権限を付与
- CMDを`main-startup.sh`に変更

## 利点

### 1. **統合された起動プロセス**
- 全ての初期化処理が1つのスクリプトで管理される
- 依存関係の順序が明確になる
- エラーハンドリングが改善される

### 2. **改善されたログ出力**
- 各ステップの進行状況が明確に表示される
- 成功/失敗の状態が視覚的に分かりやすい
- デバッグが容易になる

### 3. **適切な終了処理**
- シグナルハンドリングによる適切なサービス停止
- リソースのクリーンアップが確実に実行される

### 4. **保守性の向上**
- 起動ロジックが1箇所に集約される
- 設定変更が容易になる
- トラブルシューティングが簡単になる

## 使用方法

### Docker Composeでの起動

```bash
docker-compose up -d
```

### 直接Dockerでの起動

```bash
docker build -t comfyui-env ./build
docker run -p 8888:8888 -p 6006:6006 -p 8080:8080 -p 8188:8188 comfyui-env
```

## 環境変数

| 変数名 | デフォルト値 | 説明 |
|--------|-------------|------|
| `TENSORBOARD_AUTOSTART` | `true` | TensorBoardの自動起動を制御 |
| `JUPYTER_PORT` | `8888` | Jupyter Labのポート |
| `TENSORBOARD_PORT` | `6006` | TensorBoardのポート |
| `FILEBROWSER_PORT` | `8080` | File Browserのポート |
| `INFINITE_BROWSER_PORT` | `8188` | Infinite Browserのポート |

## サービスアクセス

起動完了後、以下のURLでサービスにアクセスできます：

- **Jupyter Lab**: http://localhost:8888
- **TensorBoard**: http://localhost:6006
- **File Browser**: http://localhost:8080
- **Infinite Browser**: http://localhost:8188

## ログファイル

各サービスのログは以下の場所に保存されます：

- Supervisor: `/var/log/supervisord.log`
- Jupyter: `/var/log/jupyter.log`
- TensorBoard: `/var/log/tensorboard.log`
- File Browser: `/var/log/filebrowser.log`
- Infinite Browser: `/var/log/infinite-browser.log`

## トラブルシューティング

### 起動に失敗する場合

1. ログファイルを確認
2. conda環境の状態を確認: `conda env list`
3. supervisorctlでサービス状態を確認: `supervisorctl status`

### サービスが起動しない場合

```bash
# コンテナ内でのデバッグ
docker exec -it <container_id> /bin/bash
supervisorctl status
supervisorctl start <service_name>
```

## 後方互換性

既存の個別スクリプト（[`init-conda-env.sh`](build/init-conda-env.sh:1)、[`start-services.sh`](build/start-services.sh:1)）は保持されているため、必要に応じて個別に実行することも可能です。
