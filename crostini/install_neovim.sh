#!/usr/bin/env bash
# install_latest_nvim.sh : 最新安定版 Neovim を ~/.local にインストールする

set -euo pipefail

# 1. OS とアーキテクチャ判定
OS=$(uname -s)
ARCH=$(uname -m)

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64)   ASSET_SUFFIX="nvim-linux64.tar.gz" ;;
      aarch64)  ASSET_SUFFIX="nvim-linux-arm64.tar.gz" ;;
      *) echo "Unsupported Linux arch: $ARCH"; exit 1 ;;
    esac
    ;;
  Darwin)
    case "$ARCH" in
      arm64)    ASSET_SUFFIX="nvim-macos-arm64.tar.gz" ;;
      x86_64)   ASSET_SUFFIX="nvim-macos-x86_64.tar.gz" ;;
      *) echo "Unsupported macOS arch: $ARCH"; exit 1 ;;
    esac
    ;;
  *)
    echo "Unsupported OS: $OS"; exit 1 ;;
esac

# 2. 最新安定版リリース JSON を取得
JSON=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/tags/stable)

# 3. 必要なアセットのダウンロード URL 取得
DL_URL=$(echo "$JSON" | jq -r --arg suffix "$ASSET_SUFFIX" '.assets[] | select(.name==$suffix) | .browser_download_url')

if [[ -z "$DL_URL" ]]; then
  echo "Could not find asset $ASSET_SUFFIX in stable release"; exit 1
fi

# 4. 作業ディレクトリ
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading $DL_URL …"
curl -L "$DL_URL" -o "$TMP_DIR/nvim.tar.gz"

# 5. macOS で署名情報をクリア
if [[ "$OS" == "Darwin" ]]; then
  xattr -c "$TMP_DIR/nvim.tar.gz"
fi

# 6. 展開
tar -xzf "$TMP_DIR/nvim.tar.gz" -C "$TMP_DIR"

# 7. 配置先 ( ~/.local )
INSTALL_DIR="$HOME/.local"
mkdir -p "$INSTALL_DIR"

# アーカイブ内のトップディレクトリを検出して move
TOPDIR=$(tar -tzf "$TMP_DIR/nvim.tar.gz" | head -n1 | cut -f1 -d"/")
mv "$TMP_DIR/$TOPDIR"/* "$INSTALL_DIR/"

echo "Neovim installed to $INSTALL_DIR"
echo "Ensure $INSTALL_DIR/bin is in your \$PATH (e.g. add 'export PATH=\"\$HOME/.local/bin:\$PATH\"' to your shell rc)."

# 8. 動作確認
"$INSTALL_DIR/bin/nvim" --version | head -n3