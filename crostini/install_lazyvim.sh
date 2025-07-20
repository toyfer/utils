#!/bin/bash
# Crostini用LazyVim自動最新版インストールスクリプト

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# 最新版のNeovimを自動取得
get_latest_nvim_version() {
    log "最新のNeovimバージョンを確認中..."
    
    # GitHub APIから最新リリースを取得
    local latest_url="https://api.github.com/repos/neovim/neovim/releases/latest"
    local version=$(curl -s "$latest_url" | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4)
    
    if [ -z "$version" ]; then
        error "最新バージョンの取得に失敗しました"
    fi
    
    echo "$version"
}

# セキュアなダウンロードと検証
download_and_verify() {
    local version=$1
    local appimage="nvim.appimage"
    local url="https://github.com/neovim/neovim/releases/download/${version}/nvim.appimage"
    
    log "Neovim ${version} をダウンロード中..."
    
    # ダウンロード
    if ! wget -q --show-progress -O "/tmp/${appimage}" "$url"; then
        error "ダウンロードに失敗しました"
    fi
    
    # 実行権限を付与
    chmod +x "/tmp/${appimage}"
    
    # 簡易的な整合性チェック（ファイルサイズで確認）
    local file_size=$(stat -c%s "/tmp/${appimage}")
    if [ "$file_size" -lt 10000000 ]; then  # 10MB未満は異常
        error "ダウンロードしたファイルが小さすぎます"
    fi
    
    log "ダウンロード完了: ${file_size} bytes"
}

# メイン処理
install_latest_nvim() {
    local current_version=""
    local latest_version=$(get_latest_nvim_version)
    
    # 現在のバージョンを確認
    if command -v nvim &> /dev/null; then
        current_version=$(nvim --version | head -n1 | grep -o 'v[0-9.]*')
        log "現在のバージョン: ${current_version}"
    fi
    
    # バージョン比較
    if [ "$current_version" = "$latest_version" ]; then
        log "既に最新版 (${latest_version}) がインストールされています"
        return 0
    fi
    
    log "最新版 (${latest_version}) をインストールします"
    
    # ダウンロードと検証
    download_and_verify "$latest_version"
    
    # インストール処理
    log "Neovimをインストール中..."
    cd /tmp
    
    # 既存のものをバックアップ
    if [ -f "/usr/local/bin/nvim" ]; then
        sudo mv /usr/local/bin/nvim "/usr/local/bin/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # AppImageを展開してインストール
    ./nvim.appimage --appimage-extract
    sudo mv squashfs-root/usr/bin/nvim /usr/local/bin/nvim
    sudo mv squashfs-root/usr/share/nvim /usr/local/share/nvim
    
    # クリーンアップ
    rm -rf squashfs-root nvim.appimage
    
    # インストール確認
    if command -v nvim &> /dev/null; then
        local installed_version=$(nvim --version | head -n1 | grep -o 'v[0-9.]*')
        log "✅ Neovim ${installed_version} のインストールが完了しました"
    else
        error "インストールに失敗しました"
    fi
}

# 実行
install_latest_nvim