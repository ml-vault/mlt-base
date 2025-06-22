# Conda Environment Usage

このDockerイメージは、`diffusion-pipe` conda環境を使用してJupyterやその他のサービスを実行します。

## 特徴

- **永続化**: conda環境とパッケージキャッシュはDockerボリュームに保存され、コンテナを再起動しても保持されます
- **ランタイム作成**: conda環境は初回起動時に自動的に作成されます
- **Python 3.12**: 最新のPython 3.12を使用

## 自動インストールされるパッケージ

初回起動時に以下のパッケージが`diffusion-pipe`環境にインストールされます：

- jupyter, jupyterlab, notebook
- matplotlib, seaborn, pandas, scikit-learn, plotly
- tensorboard, tensorflow-tensorboard-plugin-wit
- infinite-browser の依存関係

## ボリューム構成

```yaml
volumes:
  - conda-envs:/opt/miniconda/envs    # conda環境
  - conda-pkgs:/opt/miniconda/pkgs    # パッケージキャッシュ
```

## 起動順序

1. `conda-init`: conda環境の作成・確認 (priority: 100)
2. `jupyter`: Jupyter Lab起動 (priority: 200)
3. `tensorboard`: TensorBoard起動 (priority: 300)
4. `filebrowser`: File Browser起動 (priority: 400)
5. `infinite-browser`: Infinite Browser起動 (priority: 500)

## 手動でconda環境を使用する場合

コンテナ内で直接conda環境を使用したい場合：

```bash
# コンテナに入る
docker-compose exec simple-ml bash

# conda環境をアクティベート
source /opt/miniconda/bin/activate diffusion-pipe

# パッケージの追加インストール
pip install your-package

# または conda でインストール
conda install your-package
```

## ログの確認

各サービスのログは以下で確認できます：

```bash
# conda環境初期化ログ
docker-compose exec simple-ml cat /var/log/conda-init.log

# Jupyterログ
docker-compose exec simple-ml cat /var/log/jupyter.log

# TensorBoardログ
docker-compose exec simple-ml cat /var/log/tensorboard.log
```

## トラブルシューティング

### conda環境が作成されない場合

1. ログを確認：
   ```bash
   docker-compose exec simple-ml cat /var/log/conda-init.log
   ```

2. 手動で環境を再作成：
   ```bash
   docker-compose exec simple-ml /usr/local/bin/init-conda-env.sh
   ```

### パッケージが見つからない場合

conda環境がアクティブになっているか確認：
```bash
docker-compose exec simple-ml bash -c "source /opt/miniconda/bin/activate diffusion-pipe && python -c 'import sys; print(sys.executable)'"
