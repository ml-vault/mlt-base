#!/usr/bin/env python3
"""
Python 3.13でimghdrモジュールが削除された問題を解決するスクリプト
TensorBoardの互換性を確保するためのimghdr代替実装を提供
"""

import sys
import os
from pathlib import Path

def create_imghdr_replacement():
    """imghdrモジュールの代替実装を作成"""
    
    imghdr_content = '''"""Recognize image file formats based on their first few bytes."""

import os
from pathlib import Path

def what(file, h=None):
    """What image format is stored in file 'file'?"""
    if h is None:
        if isinstance(file, (str, Path)):
            try:
                with open(file, 'rb') as f:
                    h = f.read(32)
            except (IOError, OSError):
                return None
        else:
            try:
                location = file.tell()
                h = file.read(32)
                file.seek(location)
            except (IOError, OSError):
                return None
    
    if not h:
        return None
    
    # 基本的な画像フォーマットの検出
    if h.startswith(b'\\xff\\xd8\\xff'):
        return 'jpeg'
    elif h.startswith(b'\\x89PNG\\r\\n\\x1a\\n'):
        return 'png'
    elif h.startswith(b'GIF87a') or h.startswith(b'GIF89a'):
        return 'gif'
    elif h.startswith(b'RIFF') and len(h) >= 12 and h[8:12] == b'WEBP':
        return 'webp'
    elif h.startswith(b'BM') and len(h) >= 2:
        return 'bmp'
    elif h.startswith(b'\\x00\\x00\\x01\\x00') or h.startswith(b'\\x00\\x00\\x02\\x00'):
        return 'ico'
    elif h.startswith(b'\\xff\\x4f\\xff') or h.startswith(b'\\x00\\x00\\x00\\x0cjP'):
        return 'jpeg2000'
    elif h.startswith(b'FORM') and len(h) >= 12 and h[8:12] == b'ILBM':
        return 'iff'
    elif h.startswith(b'\\x76\\x2f\\x31\\x01'):
        return 'exr'
    else:
        return None

def test():
    """Minimal test function for compatibility"""
    return True

# 後方互換性のための追加関数
def test_jpeg(h, f):
    """JPEG format test"""
    return h.startswith(b'\\xff\\xd8\\xff')

def test_png(h, f):
    """PNG format test"""
    return h.startswith(b'\\x89PNG\\r\\n\\x1a\\n')

def test_gif(h, f):
    """GIF format test"""
    return h.startswith(b'GIF87a') or h.startswith(b'GIF89a')

def test_webp(h, f):
    """WebP format test"""
    return h.startswith(b'RIFF') and len(h) >= 12 and h[8:12] == b'WEBP'

def test_bmp(h, f):
    """BMP format test"""
    return h.startswith(b'BM')

# テスト関数のリスト（TensorBoardとの互換性のため）
tests = [
    test_jpeg,
    test_png,
    test_gif,
    test_webp,
    test_bmp,
]
'''

    # site-packagesディレクトリを見つける
    site_packages_dirs = [p for p in sys.path if 'site-packages' in p and os.path.isdir(p)]
    
    if not site_packages_dirs:
        print("Error: site-packages directory not found")
        return False
    
    # 最初に見つかったsite-packagesディレクトリを使用
    site_packages = site_packages_dirs[0]
    imghdr_path = os.path.join(site_packages, 'imghdr.py')
    
    try:
        with open(imghdr_path, 'w', encoding='utf-8') as f:
            f.write(imghdr_content)
        
        print(f"Successfully created imghdr replacement at: {imghdr_path}")
        
        # モジュールをテスト
        try:
            import imghdr
            print("imghdr module test: OK")
            return True
        except ImportError as e:
            print(f"imghdr module test failed: {e}")
            return False
            
    except Exception as e:
        print(f"Error creating imghdr replacement: {e}")
        return False

def main():
    """メイン関数"""
    print("=== imghdr Module Replacement Script ===")
    print(f"Python version: {sys.version}")
    
    # Python 3.13以上かチェック
    if sys.version_info >= (3, 13):
        print("Python 3.13+ detected. Creating imghdr replacement...")
        success = create_imghdr_replacement()
        if success:
            print("imghdr replacement created successfully!")
            sys.exit(0)
        else:
            print("Failed to create imghdr replacement")
            sys.exit(1)
    else:
        print("Python version is compatible with imghdr. No action needed.")
        sys.exit(0)

if __name__ == "__main__":
    main()
