#!/bin/bash

mkdir -p files/etc/openclash/core

CLASH_META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-${1}.tar.gz"
GEOIP_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

wget --no-check-certificate -qO- $CLASH_META_URL | tar xOvz > files/etc/openclash/core/clash_meta
wget --no-check-certificate -qO- $GEOIP_URL > files/etc/openclash/GeoIP.dat
wget --no-check-certificate -qO- $GEOSITE_URL > files/etc/openclash/GeoSite.dat

chmod +x files/etc/openclash/core/clash*
