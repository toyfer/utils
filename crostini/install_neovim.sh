#!/usr/bin/env bash
set -eu

## ========== 1. 取得対象の判定 ==========
# 引数が "stable" なら安定版、指定が無ければ nightly
CHANNEL=${1:-nightly}

# OS 判定とアーカイブ名
case "$(uname -s)" in
  Linux)   ARCH="linux64" ; TARBALL="nvim-${ARCH}.tar.gz"   ;;
  Darwin)
    if [[ "$(uname -m)" == "arm64" ]]; then
      ARCH="macos-arm64" ; TARBALL="nvim-${ARCH}.tar.gz"
    else
      ARCH="macos-x86_64"; TARBALL="nvim-${ARCH}.tar.gz"
    fi ;;
  *) echo "Unsupported OS"; exit 1 ;;
esac

REPO="https://github.com/neovim/neovim/releases"
URL="${REPO}/${CHANNEL}/download/${TARBALL}"

## ========== 2. ダウンロード ==========
echo "Downloading ${CHANNEL} build (${TARBALL}) ..."
curl -Lso /tmp/${TARBALL} "${URL}"

## ========== 3. 展開して置き換え ==========
tar -xzf /tmp/${TARBALL} -C /tmp
sudo rm -rf /opt/nvim                           # 旧バージョン掃除
sudo mv /tmp/nvim-${ARCH} /opt/nvim             # 新バージョン配置
sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/  # PATH 上にリンク

## ========== 4. 後片付け ==========
rm /tmp/${TARBALL}
echo "Neovim ${CHANNEL} installed to /opt/nvim 🎉"