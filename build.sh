#!/bin/bash
# Dockerized OpenWrt Build Script
set -e

REPO_URL="https://github.com/coolsnowwolf/lede"
REPO_BRANCH="master"
CONFIG_FILE="configs/x86_64.config"
DIY_SCRIPT="diy-script.sh"
CLASH_KERNEL="amd64"

WORKSPACE_DIR="$PWD"
OPENWRT_PATH="$WORKSPACE_DIR/openwrt"
ARTIFACTS_DIR="$WORKSPACE_DIR/artifacts"
export GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$WORKSPACE_DIR}"
git config --global http.sslVerify false

echo "=========================================="
echo " Starting Dockerized OpenWrt Build        "
echo "=========================================="

if [ ! -d "$OPENWRT_PATH" ]; then
    echo "=> Cloning Source Code..."
    git clone $REPO_URL -b $REPO_BRANCH openwrt
else
    echo "=> Source 'openwrt' already exists. Skipping clone."
fi

cd "$OPENWRT_PATH"

echo "=> Updating and Installing Feeds..."
cp "$WORKSPACE_DIR/$CONFIG_FILE" .config
make defconfig > /dev/null 2>&1
./scripts/feeds update -a
./scripts/feeds install -a

echo "=> Loading Custom Configuration..."
[ -d "$WORKSPACE_DIR/files" ] && cp -r "$WORKSPACE_DIR/files" "$OPENWRT_PATH/files"
[ -f "$WORKSPACE_DIR/$CONFIG_FILE" ] && cp "$WORKSPACE_DIR/$CONFIG_FILE" "$OPENWRT_PATH/.config"

chmod +x "$WORKSPACE_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$WORKSPACE_DIR/$DIY_SCRIPT"

"$WORKSPACE_DIR/$DIY_SCRIPT"

[ -f "$WORKSPACE_DIR/scripts/preset-clash-core.sh" ] && "$WORKSPACE_DIR/scripts/preset-clash-core.sh" $CLASH_KERNEL
[ -f "$WORKSPACE_DIR/scripts/preset-terminal-tools.sh" ] && "$WORKSPACE_DIR/scripts/preset-terminal-tools.sh"
[ -f "$WORKSPACE_DIR/scripts/preset-adguard-core.sh" ] && "$WORKSPACE_DIR/scripts/preset-adguard-core.sh" $CLASH_KERNEL

echo "=> Downloading Packages..."
make defconfig
make download -j8

echo "=> Compiling Firmware with $(nproc) threads..."
mkdir -p files/etc/uci-defaults
[ -f "$WORKSPACE_DIR/scripts/init-settings.sh" ] && cp "$WORKSPACE_DIR/scripts/init-settings.sh" files/etc/uci-defaults/99-init-settings

# Attempt multi-thread, fallback to single-thread with verbose logging on failure
set +e
make -j$(nproc) V=sc || make -j1 || make -j1 V=s
BUILD_STATUS=$?
set -e

if [ $BUILD_STATUS -ne 0 ]; then
    echo "❌ Compilation failed."
    exit 1
fi

echo "=> Organizing Artifacts..."
mkdir -p "$ARTIFACTS_DIR"
cp -r "$OPENWRT_PATH/bin/targets/"* "$ARTIFACTS_DIR/"
cp "$OPENWRT_PATH/.config" "$ARTIFACTS_DIR/build.config"

echo "✅ Build Complete! Firmware saved to ./artifacts"
