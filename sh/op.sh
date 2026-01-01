#!/bin/bash

set -x

function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../
  cd .. && rm -rf $repodir
}

git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/network/config/firewall
git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/network/config/firewall4
git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/network/utils/fullconenat-nft
git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/network/utils/fullconenat
git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/network/utils/nftables
git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/kernel/linux/modules
git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/libs/libnftnl
git_sparse_clone master https://github.com/immortalwrt/immortalwrt target/linux/generic
git_sparse_clone master https://github.com/immortalwrt/luci applications/luci-app-firewall

rm -rf package/network/{config/firewall,config/firewall4,utils/nftables}
rm -rf target/linux/generic
mv -v generic target/linux

mv -v {firewall,firewall4} package/network/config
mv -v {nftables,fullconenat,fullconenat-nft} package/network/utils
rm -rf package/libs/libnftnl
mv -v libnftnl package/libs
rm -rf package/kernel/linux/modules
mv -v modules package/kernel/linux


git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/emortal/automount

git_sparse_clone master https://github.com/immortalwrt/immortalwrt package/emortal/autosamba

cp -rf {automount,autosamba} package


git clone https://github.com/sbwml/autocore-arm package/autocore-arm -b openwrt-25.12 --depth 1

rm -rf package/autocore-arm/.git

git clone -b packages --depth 1 --single-branch https://github.com/shiyu1314/openwrt-feeds package/xd
git clone -b porxy --depth 1 --single-branch https://github.com/shiyu1314/openwrt-feeds package/porxy


rm -rf feeds/luci/applications/{luci-app-firewall,luci-app-dockerman,luci-app-samba4,luci-app-aria2}
rm -rf feeds/packages/net/{samba4,v2ray-geodata,mosdns,sing-box,aria2,ariang,adguardhome}
rm -rf feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/29_ports.js

mv -v luci-app-firewall feeds/luci/applications

# kenrel Vermagic
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' include/kernel-defaults.mk
grep HASH target/linux/generic/kernel-6.12 | awk -F'HASH-' '{print $2}' | awk '{print $1}' | md5sum | awk '{print $1}' > .vermagic


sed -i 's/^PKG_BUILD_PARALLEL:=1$/PKG_BUILD_PARALLEL:=1\nPKG_FORTIFY_SOURCE:=0/' package/libs/xcrypt/libxcrypt/Makefile



sed -i '/+luci-app-attendedsysupgrade/d' feeds/luci/collections/luci/Makefile
sed -i 's/+luci-app-package-manager \\$/+luci-app-package-manager/' feeds/luci/collections/luci/Makefile

sed -i '/+luci-app-attendedsysupgrade/d' feeds/luci/collections/luci-nginx/Makefile

sed -i '/+luci-app-attendedsysupgrade/d' feeds/luci/collections/luci-ssl-openssl/Makefile
sed -i 's/+luci-app-package-manager \\$/+luci-app-package-manager/' feeds/luci/collections/luci-ssl-openssl/Makefile

sed -i '/+luci-app-attendedsysupgrade/d' feeds/luci/collections/luci-ssl/Makefile
sed -i 's/+luci-app-package-manager \\$/+luci-app-package-manager/' feeds/luci/collections/luci-ssl/Makefile


sed -i 's/libustream-mbedtls/libustream-openssl/' include/target.mk



pushd feeds/luci
    patch -p1 < 0001-luci-mod-system-add-modal-overlay-dialog-to-reboot.patch
    patch -p1 < 0002-luci-mod-status-displays-actual-process-memory-usage.patch
    patch -p1 < 0003-luci-mod-status-storage-index-applicable-only-to-val.patch
    patch -p1 < 0004-luci-mod-status-firewall-disable-legacy-firewall-rul.patch
    patch -p1 < 0005-luci-mod-system-add-refresh-interval-setting.patch
    patch -p1 < 0006-luci-mod-system-mounts-add-docker-directory-mount-po.patch
    patch -p1 < 0007-luci-mod-system-add-ucitrack-luci-mod-system-zram.js.patch
    patch -p1 < 0008-luci-mod-network-add-option-for-ipv6-max-plt-vlt.patch
    patch -p1 < 0004-luci-add-firewall-add-custom-nft-rule-support.patch
popd



patch -p1 < 100-openwrt-firewall4-add-custom-nft-command-support.patch


#golang 26.x
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

./scripts/feeds update -a
./scripts/feeds install -a


sed -i 's|/bin/login|/bin/login -f root|g' feeds/packages/utils/ttyd/files/ttyd.config

sudo rm -rf package/base-files/files/etc/banner

sed -i "s/%D %V %C/%D %V $(TZ=UTC-8 date +%Y.%m.%d)/" package/base-files/files/etc/openwrt_release

sed -i "s/%R/by $OP_author/" package/base-files/files/etc/openwrt_release

date=$(date +"%Y-%m-%d")
echo "                                                    " >> package/base-files/files/etc/banner
echo "  _______                     ________        __" >> package/base-files/files/etc/banner
echo " |       |.-----.-----.-----.|  |  |  |.----.|  |_" >> package/base-files/files/etc/banner
echo " |   -   ||  _  |  -__|     ||  |  |  ||   _||   _|" >> package/base-files/files/etc/banner
echo " |_______||   __|_____|__|__||________||__|  |____|" >> package/base-files/files/etc/banner
echo "          |__|" >> package/base-files/files/etc/banner
echo " -----------------------------------------------------" >> package/base-files/files/etc/banner
echo "         %D ${date} by $OP_author                     " >> package/base-files/files/etc/banner
echo " -----------------------------------------------------" >> package/base-files/files/etc/banner
