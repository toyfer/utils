#!/bin/bash
# Crostini用LazyVim一発インストールスクリプト

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# システム更新
log "システムを更新中..."
sudo apt update && sudo apt upgrade -y

# 必要なパッケージのインストール
log "必要なパッケージをインストール中..."
sudo apt install -y \
    git \
    curl \
    wget \
    ripgrep \
    fd-find \
    build-essential \
    unzip \
    gettext \
    cmake \
    ninja-build \
    pkg-config \
    libtool \
    libtool-bin \
    autoconf \
    automake \
    doxygen

# Neovimの最新版をインストール
log "Neovimをインストール中..."
if ! command -v nvim &> /dev/null; then
    # AppImageを使用して最新版をインストール
    NVIM_VERSION="v0.10.1"
    NVIM_FILE="nvim.appimage"
    
    wget -O /tmp/nvim.appimage "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim.appimage"
    chmod +x /tmp/nvim.appimage
    
    # 展開してインストール
    cd /tmp
    ./nvim.appimage --appimage-extract
    sudo mv squashfs-root/usr/bin/nvim /usr/local/bin/nvim
    sudo mv squashfs-root/usr/share/nvim /usr/local/share/nvim
    rm -rf squashfs-root nvim.appimage
    
    log "Neovim ${NVIM_VERSION} をインストールしました"
else
    log "Neovimは既にインストールされています"
fi

# Nerd Fontのインストール（オプション）
log "Nerd Fontをインストール中..."
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# JetBrainsMono Nerd Fontをダウンロード
if [ ! -f "$FONT_DIR/JetBrainsMonoNerdFont-Regular.ttf" ]; then
    wget -O /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip"
    cd /tmp
    unzip -o JetBrainsMono.zip -d JetBrainsMono
    cp JetBrainsMono/*.ttf "$FONT_DIR/"
    fc-cache -fv
    rm -rf JetBrainsMono JetBrainsMono.zip
    log "Nerd Fontをインストールしました"
fi

# LazyVimのインストール
log "LazyVimをインストール中..."
if [ -d "$HOME/.config/nvim" ]; then
    warning "既存のNeovim設定が見つかりました。バックアップを作成します..."
    mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

if [ -d "$HOME/.local/share/nvim" ]; then
    mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.backup.$(date +%Y%m%d_%H%M%S)"
fi

# LazyVimのクローン
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"

# 初回起動（プラグインの自動インストール）
log "LazyVimの初回セットアップを実行中..."
nvim --headless "+Lazy! sync" +qa

# 追加の便利ツール
log "追加ツールをインストール中..."
sudo apt install -y \
    tree \
    htop \
    bat \
    exa \
    zoxide

# クリップボード共有のためのxclip
sudo apt install -y xclip

# 完了メッセージ
log "インストールが完了しました！"
echo ""
echo "=============================================="
echo "LazyVimが正常にインストールされました！"
echo ""
echo "起動方法: nvim"
echo ""
echo "初回起動時にプラグインが自動的にインストールされます"
echo "（初回は数分かかる場合があります）"
echo ""
echo "ターミナルで 'nvim' を実行して開始してください"
echo "=============================================="