#!/usr/bin/env bash

source /etc/profile
BASE_PATH=$(cd $(dirname $0) && pwd)

BUILD_DIR="lede"

if [[ ! -d $BASE_PATH/$BUILD_DIR ]]; then
	git clone https://github.com/coolsnowwolf/lede.git ./$BUILD_DIR
fi

cd $BASE_PATH/$BUILD_DIR
status_cfg=$(git status | grep -E "\.config$" | wc -l)
if [[ $status_cfg -gt 0 ]]; then
    git reset HEAD .config
    git checkout .config
fi

status_cfg=$(git status | grep -E "feeds.conf.default$" | wc -l)
if [[ $status_cfg -gt 0 ]]; then
    git reset HEAD feeds.conf.default
    git checkout feeds.conf.default
fi

\rm -rf ./tmp
\rm -rf ./logs/*

git pull

echo "src-git small8 https://github.com/kenzok8/small-package" >> feeds.conf.default

./scripts/feeds clean
./scripts/feeds update -a

\rm -rf ./feeds/luci/applications/{luci-app-smartdns,luci-app-rclone,luci-app-haproxy-tcp,luci-app-mosdns}
\rm -rf ./feeds/luci/themes/luci-theme-argon
\rm -rf ./feeds/packages/net/{haproxy,mosdns,smartdns,ddns-go,adguardhome}
\rm -rf ./feeds/small8/{ppp,firewall,dae,daed,daed-next,libnftnl,nftables,dnsmasq}

if [[ -d ./feeds/packages/lang/golang ]]; then
    \rm -rf ./feeds/packages/lang/golang
    git clone https://github.com/sbwml/packages_lang_golang.git -b 22.x ./feeds/packages/lang/golang
fi

./scripts/feeds update -i
./scripts/feeds install -f -ap packages
./scripts/feeds install -f -ap luci
./scripts/feeds install -f -ap routing
./scripts/feeds install -f -ap telephony

./scripts/feeds install -p small8 -f luci-app-adguardhome xray-core xray-plugin dns2tcp dns2socks haproxy \
luci-app-passwall luci-app-mosdns luci-app-smartdns luci-app-ddns-go luci-app-cloudflarespeedtest taskd \
luci-lib-xterm luci-lib-taskd luci-app-store quickstart luci-app-quickstart luci-app-istorex luci-theme-argone \
luci-app-udp2raw
