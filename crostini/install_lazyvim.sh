#!//bash/bash
# Crostini用LazyVim完全自動インストールスクリプト

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

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# 依存関係のインストール
install_dependencies() {
    log "依存関係をインストール中..."
    
    # 基本パッケージ
    local basic_deps=(
        git
        curl
        wget
        unzip
        tar
        gzip
    )
    
    # LazyVim用パッケージ
    local lazyvim_deps=(
        ripgrep
        fd-find
        nodejs
        npm
        python3
        python3-pip
        build-essential
        cmake
    )
    
    # Crostini用パッケージ
    local crostini_deps=(
        xclip
        fonts-noto-color-emoji
    )
    
    # 全パッケージを結合
    local all_deps=("${basic_deps[@]}" "${lazyvim_deps[@]}" "${crostini_deps[@]}")
    
    sudo apt update
    sudo apt install -y "${all_deps[@]}"
    
    # fd-findのエイリアスを作成（fdコマンドを使えるように）
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd
    fi
    
    log "依存関係のインストール完了"
}

# 最新版のNeovimを自動取得
get_latest_nvim_version() {
    log "最新のNeovimバージョンを確認中..."
    
    local version=$(curl -s "https://api.github.com/repos/neovim/neovim/releases/latest" | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4)
    
    if [ -z "$version" ]; then
        error "最新バージョンの取得に失敗しました"
    fi
    
    echo "$version"
}

# セキュアなダウンロード
download_file() {
    local url=$1
    local output=$2
    
    log "ダウンロード中: $url"
    curl -L --progress-bar --retry 3 --retry-delay 5 -o "$output" "$url"
}

# Neovimのインストール
install_neovim() {
    local latest_version=$(get_latest_nvim_version)
    log "最新バージョン: $latest_version"
    
    local appimage_url="https://github.com/neovim/neovim/releases/download/${latest_version}/nvim.appimage"
    local temp_file="/tmp/nvim-${latest_version}.appimage"
    
    download_file "$appimage_url" "$temp_file"
    
    # 実行権限とインストール
    chmod +x "$temp_file"
    
    log "Neovimをインストール中..."
    cd /tmp
    "$temp_file" --appimage-extract
    
    sudo mv squashfs-root/usr/bin/nvim /usr/local/bin/nvim
    sudo mv squashfs-root/usr/share/nvim /usr/local/share/nvim
    
    # クリーンアップ
    rm -rf squashfs-root "$temp_file"
    
    log "✅ Neovim ${latest_version} のインストール完了"
}

# LazyVimのインストール
install_lazyvim() {
    log "LazyVimをインストール中..."
    
    # バックアップ
    if [ -d "$HOME/.config/nvim" ]; then
        warning "既存のNeovim設定をバックアップします"
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    if [ -d "$HOME/.local/share/nvim" ]; then
        mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # LazyVimのクローン
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
    
    # 初回起動（プラグイン自動インストール）
    log "LazyVimの初回セットアップ中..."
    nvim --headless "+Lazy! sync" +qa
    
    log "✅ LazyVimのインストール完了"
}

# メイン処理
main() {
    log "=== LazyVim完全自動インストール開始 ==="
    
    # 依存関係
    install_dependencies
    
    # Neovim
    install_neovim
    
    # LazyVim
    install_lazyvim
    
    log ""
    log "=============================================="
    log "🎉 インストールが完了しました！"
    log "起動方法: nvim"
    log "初回起動時にプラグインが自動インストールされます"
    log "=============================================="
}

# 実行
main