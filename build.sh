#!/usr/bin/env bash

source /etc/profile
BASE_PATH=$(cd $(dirname $0) && pwd)

BUILD_DIR="lede"

dev_mod=$1
clear=$2

if [[ ! -f $BASE_PATH/diffconfig.$dev_mod ]]; then
    echo "config not fond: diffconfig.$dev_mod"
    exit 0
fi

$BASE_PATH/update.sh

cd $BASE_PATH/$BUILD_DIR

is_mips=$(grep -cE "^CONFIG_TARGET_ramips=y$" $BASE_PATH/diffconfig.$dev_mod)
if [[ $is_mips -gt 0 ]]; then
    for mkfile in $(find -L package/feeds/ -name "Makefile"); do
        sed -i 's/PKG_BUILD_FLAGS:=no-mips16/PKG_USE_MIPS16:=0/g' $mkfile
        NOMIPS16=$(grep -cE "^PKG_USE_MIPS16:=0$" $mkfile)
        GOPKG=$(grep -cE "^GO_PKG:=" $mkfile)
        if [[ $NOMIPS16 -eq 0 ]] && [[ $GOPKG -gt 0 ]]; then
            sed -i '/GO_PKG/a PKG_USE_MIPS16:=0' $mkfile
            echo "fix Makefile for nomips16: $mkfile"
        fi
    done
    if [[ -f feeds/small8/haproxy/Makefile ]]; then
        sed -i '/PKG_CPE_ID/a PKG_USE_MIPS16:=0' feeds/small8/haproxy/Makefile
        echo "fix Makefile for nomips16: feeds/small8/haproxy/Makefile"
    fi
fi

if [[ $clear == "clear" ]]; then
    find ./ -name "*.ipk" | xargs \rm -f
fi

\cp -f $BASE_PATH/diffconfig.$dev_mod .config

make defconfig

if [[ $clear == "debug" ]]; then
    exit 0
fi

make download -j$(nproc)
if [[ $clear == "clear" ]]; then
    make -j1 V=s
else
    make -j$(nproc) V=s
fi
