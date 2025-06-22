# ComfyUI with Conda Support

このDockerイメージは、従来のPython仮想環境に加えてCondaもサポートしています。

## 利用可能な環境

### 従来のPython仮想環境
- `comfyui` - ComfyUI用の仮想環境
- `api` - API Wrapper用の仮想環境  
- `infinite-browser` - Infinite Browser用の仮想環境

### Conda環境
- `comfyui` - ComfyUI用のConda環境
- `api` - API Wrapper用のConda環境
- `infinite-browser` - Infinite Browser用のConda環境

## Conda環境の使用方法

### 1. Conda環境の確認
```bash
conda env list
```

### 2. Conda環境のアクティベート
```bash
# ヘルパースクリプトを使用
source /opt/ai-dock/bin/conda-activate.sh comfyui

# または直接condaコマンドを使用
conda activate comfyui
```

### 3. ComfyUIをConda環境で実行
```bash
# Supervisorを使用してConda環境でComfyUIを起動
supervisorctl start comfyui-conda

# または手動で起動
conda activate comfyui
cd /opt/ComfyUI
python main.py --port 8188
```

## 環境の切り替え

### 従来の仮想環境を使用する場合
```bash
supervisorctl start comfyui
```

### Conda環境を使用する場合
```bash
supervisorctl start comfyui-conda
```

## パッケージの管理

### Conda環境でのパッケージインストール
```bash
conda activate comfyui
pip install package_name
# または
conda install package_name
```

### 従来の仮想環境でのパッケージインストール
```bash
source /opt/venvs/comfyui/bin/activate
pip install package_name
```

## 環境変数

以下の環境変数が設定されています：

- `CONDA_DIR=/opt/miniconda` - Condaのインストールディレクトリ
- `COMFYUI_CONDA_ENV=comfyui` - ComfyUI用のConda環境名
- `API_CONDA_ENV=api` - API用のConda環境名
- `INFINITE_BROWSER_CONDA_ENV=infinite-browser` - Infinite Browser用のConda環境名

## 注意事項

1. 従来の仮想環境とConda環境は独立しています
2. 同時に両方のComfyUIサービス（`comfyui`と`comfyui-conda`）を起動しないでください
3. Conda環境は`/opt/miniconda`にインストールされています
4. 各環境には同じパッケージがインストールされていますが、独立して管理されます

## トラブルシューティング

### Conda環境が見つからない場合
```bash
export PATH="/opt/miniconda/bin:$PATH"
source /opt/miniconda/etc/profile.d/conda.sh
```

### 環境の再作成
```bash
conda env remove -n comfyui
conda create -n comfyui python=3.10 -y
conda activate comfyui
cd /opt/ComfyUI
pip install -r requirements.txt
