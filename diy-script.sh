#!/bin/bash

# git clone retry wrapper
git() {
  if [ "$1" = "clone" ]; then
    shift
    local last_arg="${@: -1}"
    if [[ ! "$last_arg" =~ ^- ]] && [[ ! "$last_arg" =~ ^https?:// ]] && [[ ! "$last_arg" =~ ^git@ ]] && [ -d "$last_arg" ]; then
      echo "=> Destination path '$last_arg' already exists. Skipping clone."
      return 0
    fi
    local max_retries=5
    local count=0
    until command git clone "$@"; do
      count=$((count + 1))
      if [ $count -ge $max_retries ]; then
        echo "Failed to clone after $max_retries attempts: git clone $@"
        return 1
      fi
      echo "Clone failed, retrying in 3 seconds ($count/$max_retries)..."
      sleep 3
    done
  else
    command git "$@"
  fi
}

# 修改默认IP
sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate

# 更改默认 Shell 为 zsh
# sed -i 's/\/bin\/ash/\/usr\/bin\/zsh/g' package/base-files/files/etc/passwd

# TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

# 移除要替换的包
rm -rf feeds/packages/net/adguardhome
rm -rf feeds/packages/net/mosdns
rm -rf feeds/packages/net/msd_lite
# rm -rf feeds/packages/net/smartdns
rm -rf feeds/packages/net/open-app-filter
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  local repodir
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  local max_retries=5
  local count=0
  
  while [ $count -lt $max_retries ]; do
    rm -rf "$repodir"
    if git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl; then
      if cd "$repodir" && git sparse-checkout set "$@"; then
        local all_exist=true
        for item in "$@"; do
          if [ ! -e "$item" ]; then
            all_exist=false
            break
          fi
        done
        if [ "$all_exist" = "true" ]; then
          mv -f "$@" ../package
          cd ..
          rm -rf "$repodir"
          return 0
        fi
      fi
      cd ..
    fi
    count=$((count + 1))
    echo "Sparse clone or checkout failed, retrying in 3 seconds ($count/$max_retries)..."
    sleep 3
  done
  echo "Failed sparse clone of $repourl after $max_retries attempts"
  return 1
}

# 添加额外插件
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome
git clone --depth=1 -b openwrt-18.06 https://github.com/tty228/luci-app-wechatpush package/luci-app-serverchan
git clone --depth=1 https://github.com/ilxp/luci-app-ikoolproxy package/luci-app-ikoolproxy
git clone --depth=1 https://github.com/esirplayground/luci-app-poweroff package/luci-app-poweroff
git clone --depth=1 https://github.com/destan19/OpenAppFilter package/OpenAppFilter
git clone --depth=1 https://github.com/Jason6111/luci-app-netdata package/luci-app-netdata
git_sparse_clone main https://github.com/Lienol/openwrt-package luci-app-filebrowser luci-app-ssr-mudb-server
git_sparse_clone openwrt-18.06 https://github.com/immortalwrt/luci applications/luci-app-eqos
# git_sparse_clone master https://github.com/syb999/openwrt-19.07.1 package/network/services/msd_lite

# 科学上网插件
git clone --depth=1 -b main https://github.com/fw876/helloworld package/luci-app-ssr-plus
[ -f package/luci-app-ssr-plus/luci-app-ssr-plus/Makefile ] && sed -i '/libustream-mbedtls||/d' package/luci-app-ssr-plus/luci-app-ssr-plus/Makefile
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall-packages package/openwrt-passwall
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall package/luci-app-passwall
git clone --depth=1 https://github.com/Openwrt-Passwall/openwrt-passwall2 package/luci-app-passwall2
git_sparse_clone master https://github.com/vernesong/OpenClash luci-app-openclash

# Themes
git clone --depth=1 -b 18.06 https://github.com/kiddin9/luci-theme-edge package/luci-theme-edge
git clone --depth=1 -b 18.06 https://github.com/jerrykuku/luci-theme-argon package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config package/luci-app-argon-config
git clone --depth=1 https://github.com/xiaoqingfengATGH/luci-theme-infinityfreedom package/luci-theme-infinityfreedom
git_sparse_clone main https://github.com/haiibo/packages luci-theme-atmaterial luci-theme-opentomcat luci-theme-netgear

# 更改 Argon 主题背景
if [ -f $GITHUB_WORKSPACE/images/bg1.gif ]; then
  mkdir -p package/luci-theme-argon/htdocs/luci-static/argon/background/
  cp -f $GITHUB_WORKSPACE/images/bg1.gif package/luci-theme-argon/htdocs/luci-static/argon/background/bg1.gif
  rm -f package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
elif [ -f $GITHUB_WORKSPACE/images/bg1.webp ]; then
  mkdir -p package/luci-theme-argon/htdocs/luci-static/argon/background/
  cp -f $GITHUB_WORKSPACE/images/bg1.webp package/luci-theme-argon/htdocs/luci-static/argon/background/bg1.webp
  rm -f package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
else
  cp -f $GITHUB_WORKSPACE/images/bg1.jpg package/luci-theme-argon/htdocs/luci-static/argon/img/bg1.jpg
fi

# 晶晨宝盒
git_sparse_clone main https://github.com/ophub/luci-app-amlogic luci-app-amlogic
sed -i "s|firmware_repo.*|firmware_repo 'https://github.com/wheelhorse/OpenRouter'|g" package/luci-app-amlogic/root/etc/config/amlogic
# sed -i "s|kernel_path.*|kernel_path 'https://github.com/ophub/kernel'|g" package/luci-app-amlogic/root/etc/config/amlogic
sed -i "s|ARMv8|ARMv8_PLUS|g" package/luci-app-amlogic/root/etc/config/amlogic

# SmartDNS
#git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
#git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns

# msd_lite
git clone --depth=1 https://github.com/ximiTech/luci-app-msd_lite package/luci-app-msd_lite
git clone --depth=1 https://github.com/ximiTech/msd_lite package/msd_lite

# MosDNS
git clone --depth=1 https://github.com/sbwml/luci-app-mosdns package/luci-app-mosdns

# Alist
git clone --depth=1 https://github.com/sbwml/luci-app-alist package/luci-app-alist

# DDNS.to
git_sparse_clone main https://github.com/linkease/nas-packages-luci luci/luci-app-ddnsto
git_sparse_clone master https://github.com/linkease/nas-packages network/services/ddnsto

# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# 在线用户
git_sparse_clone main https://github.com/haiibo/packages luci-app-onliner
sed -i '$i uci set nlbwmon.@nlbwmon[0].refresh_interval=2s' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit nlbwmon' package/lean/default-settings/files/zzz-default-settings

# 添加 getip 脚本到 base-files 并设置 DDNS 默认使用自定义 getip 脚本
mkdir -p package/base-files/files/usr/bin
cp -f $GITHUB_WORKSPACE/docker/patches/getip package/base-files/files/usr/bin/getip
chmod +x package/base-files/files/usr/bin/getip
sed -i '$i uci set ddns.myddns_ipv4.ip_source=script' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci set ddns.myddns_ipv4.ip_script=/usr/bin/getip' package/lean/default-settings/files/zzz-default-settings
sed -i '$i uci commit ddns' package/lean/default-settings/files/zzz-default-settings
chmod 755 package/luci-app-onliner/root/usr/share/onliner/setnlbw.sh

# x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 修改本地时间格式
sed -i 's/os.date()/os.date("%a %Y-%m-%d %H:%M:%S")/g' package/lean/autocore/files/*/index.htm

# 修改版本为编译日期
date_version=$(date +"%y.%m.%d")
orig_version=$(cat "package/lean/default-settings/files/zzz-default-settings" | grep DISTRIB_REVISION= | awk -F "'" '{print $2}')
sed -i "s/${orig_version}/R${date_version} by Haiibo/g" package/lean/default-settings/files/zzz-default-settings

# 修复 hostapd 报错
cp -f $GITHUB_WORKSPACE/scripts/011-fix-mbo-modules-build.patch package/network/services/hostapd/patches/011-fix-mbo-modules-build.patch

# 修复 transmission miniupnpc 报错
mkdir -p feeds/packages/net/transmission/patches
cp -f $GITHUB_WORKSPACE/scripts/0004-fix-miniupnpc-2.3-compat.patch feeds/packages/net/transmission/patches/0004-fix-miniupnpc-2.3-compat.patch

# 修复 samba4 与 autosamba 冲突的 20-smb 热插拔脚本重复问题
[ -f feeds/packages/net/samba4/Makefile ] && sed -i '/etc\/hotplug\.d\/block/d' feeds/packages/net/samba4/Makefile
[ -f package/network/services/samba36/Makefile ] && sed -i '/etc\/hotplug\.d\/block/d' package/network/services/samba36/Makefile

# 修复 armv8 设备 xfsprogs 报错
sed -i 's/TARGET_CFLAGS.*/TARGET_CFLAGS += -DHAVE_MAP_SYNC -D_LARGEFILE64_SOURCE/g' feeds/packages/utils/xfsprogs/Makefile

# 修改 Makefile
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/luci.mk/$(TOPDIR)\/feeds\/luci\/luci.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/..\/..\/lang\/golang\/golang-package.mk/$(TOPDIR)\/feeds\/packages\/lang\/golang\/golang-package.mk/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHREPO/PKG_SOURCE_URL:=https:\/\/github.com/g' {}
find package/*/ -maxdepth 2 -path "*/Makefile" | xargs -i sed -i 's/PKG_SOURCE_URL:=@GHCODELOAD/PKG_SOURCE_URL:=https:\/\/codeload.github.com/g' {}

# 取消主题默认设置
find package/luci-theme-*/* -type f -name '*luci-theme-*' -print -exec sed -i '/set luci.main.mediaurlbase/d' {} \;

# 调整 V2ray服务器 到 VPN 菜单
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/controller/*.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/model/cbi/v2ray_server/*.lua
# sed -i 's/services/vpn/g' feeds/luci/applications/luci-app-v2ray-server/luasrc/view/v2ray_server/*.htm

./scripts/feeds update -a
./scripts/feeds install -a


