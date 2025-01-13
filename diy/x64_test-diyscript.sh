#!/bin/bash

# 修改默认IP
sed -i 's/192.168.1.1/10.0.0.1/g' package/base-files/files/bin/config_generate

# profile
sed -i 's#\\u@\\h:\\w\\\$#\\[\\e[32;1m\\][\\u@\\h\\[\\e[0m\\] \\[\\033[01;34m\\]\\W\\[\\033[00m\\]\\[\\e[32;1m\\]]\\[\\e[0m\\]\\\$#g' package/base-files/files/etc/profile
sed -ri 's/(export PATH=")[^"]*/\1%PATH%:\/opt\/bin:\/opt\/sbin:\/opt\/usr\/bin:\/opt\/usr\/sbin/' package/base-files/files/etc/profile
sed -i '/PS1/a\export TERM=xterm-color' package/base-files/files/etc/profile

# TTYD
sed -i 's/services/system/g' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i '3 a\\t\t"order": 50,' feeds/luci/applications/luci-app-ttyd/root/usr/share/luci/menu.d/luci-app-ttyd.json
sed -i 's/procd_set_param stdout 1/procd_set_param stdout 0/g' feeds/packages/utils/ttyd/files/ttyd.init
sed -i 's/procd_set_param stderr 1/procd_set_param stderr 0/g' feeds/packages/utils/ttyd/files/ttyd.init

# bash
sed -i 's#ash#bash#g' package/base-files/files/etc/passwd
sed -i '\#export ENV=/etc/shinit#a export HISTCONTROL=ignoredups' package/base-files/files/etc/profile
mkdir -p files/root
curl -so files/root/.bash_profile https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/files/raw/branch/main/root/.bash_profile
curl -so files/root/.bashrc https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/files/raw/branch/main/root/.bashrc

# 移除要替换的包
rm -rf feeds/packages/net/{xray-core,v2ray-core,v2ray-geodata,sing-box,adguardhome,socat}
rm -rf feeds/packages/net/alist feeds/luci/applications/luci-app-alist
rm -rf feeds/packages/utils/v2dat
rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  branch="$1" repourl="$2" && shift 2
  git clone --depth=1 -b $branch --single-branch --filter=blob:none --sparse $repourl
  repodir=$(echo $repourl | awk -F '/' '{print $(NF)}')
  cd $repodir && git sparse-checkout set $@
  mv -f $@ ../package
  cd .. && rm -rf $repodir
}

# golong1.23依赖
#git clone --depth=1 https://github.com/sbwml/packages_lang_golang -b 22.x feeds/packages/lang/golang
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/packages_lang_golang -b 23.x feeds/packages/lang/golang

# SSRP & Passwall
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/openwrt_helloworld.git package/helloworld -b v5

# Alist
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-alist package/alist

# Mosdns
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-mosdns.git -b v5 package/mosdns
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/v2ray-geodata.git package/v2ray-geodata

# Realtek 网卡 - R8168 & R8125 & R8126 & R8152 & R8101
rm -rf package/kernel/r8168 package/kernel/r8101 package/kernel/r8125 package/kernel/r8126
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/package_kernel_r8168 package/kernel/r8168
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/package_kernel_r8152 package/kernel/r8152
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/package_kernel_r8101 package/kernel/r8101
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/package_kernel_r8125 package/kernel/r8125
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/package_kernel_r8126 package/kernel/r8126

# Adguardhome
git_sparse_clone master https://github.com/kenzok8/openwrt-packages adguardhome luci-app-adguardhome

# iStore
git_sparse_clone main https://github.com/linkease/istore-ui app-store-ui
git_sparse_clone main https://github.com/linkease/istore luci

# Docker
rm -rf feeds/luci/applications/luci-app-dockerman
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-dockerman -b 24.10 feeds/luci/applications/luci-app-dockerman
rm -rf feeds/packages/utils/{docker,dockerd,containerd,runc}
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/packages_utils_docker feeds/packages/utils/docker
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/packages_utils_dockerd feeds/packages/utils/dockerd
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/packages_utils_containerd feeds/packages/utils/containerd
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/packages_utils_runc feeds/packages/utils/runc
sed -i '/sysctl.d/d' feeds/packages/utils/dockerd/Makefile
pushd feeds/packages
    curl -s https://init.cooluc.com/openwrt/patch/docker/0001-dockerd-fix-bridge-network.patch | patch -p1
    curl -s https://init.cooluc.com/openwrt/patch/docker/0002-docker-add-buildkit-experimental-support.patch | patch -p1
    curl -s https://init.cooluc.com/openwrt/patch/docker/0003-dockerd-disable-ip6tables-for-bridge-network-by-defa.patch | patch -p1
popd

# UPnP
rm -rf feeds/{packages/net/miniupnpd,luci/applications/luci-app-upnp}
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/miniupnpd feeds/packages/net/miniupnpd -b v2.3.7
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-upnp feeds/luci/applications/luci-app-upnp -b master

# fstools
rm -rf package/system/fstools
git clone https://github.com/sbwml/package_system_fstools -b openwrt-24.10 package/system/fstools

# util-linux
rm -rf package/utils/util-linux
git clone https://github.com/sbwml/package_utils_util-linux -b openwrt-24.10 package/utils/util-linux

# Lucky
git clone --depth=1 https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-lucky package/luci-app-lucky

# Zero-package
git clone --depth=1 https://github.com/oppen321/Zero-package package/Zero-package

# 一键配置拨号
git clone --depth=1 https://github.com/sirpdboy/luci-app-netwizard package/luci-app-netwizard

# 在线更新
git clone --depth=1 https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-gpsysupgrade package/luci-app-gpsysupgrade

# 修改名称
sed -i 's/OpenWrt/OpenWrt-GXNAS/' package/base-files/files/bin/config_generate

# 自定义设置
cp -f $GITHUB_WORKSPACE/diy/banner package/base-files/files/etc/banner

# default settings
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/default-settings package/new/default-settings -b openwrt-24.10

# Theme
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-theme-argon.git package/new/luci-theme-argon
cp -f $GITHUB_WORKSPACE/images/bg.webp package/new/luci-theme-argon/luci-theme-argon/htdocs/luci-static/argon/img/bg.webp

# OpenAppFilter
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/OpenAppFilter --depth=1 package/OpenAppFilter

# luci-app-partexp
git clone --depth=1 https://github.com/sirpdboy/luci-app-partexp package/luci-app-partexp

# luci-app-webdav
git clone https://$GIT_USERNAME:$GIT_PASSWORD@git.kejizero.online/zhao/luci-app-webdav package/new/luci-app-webdav

# FullCone module
git clone https://git.cooluc.com/sbwml/nft-fullcone package/new/nft-fullcone

# unzip
rm -rf feeds/packages/utils/unzip
git clone https://github.com/sbwml/feeds_packages_utils_unzip feeds/packages/utils/unzip

# luci-compat - fix translation
sed -i 's/<%:Up%>/<%:Move up%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm
sed -i 's/<%:Down%>/<%:Move down%>/g' feeds/luci/modules/luci-compat/luasrc/view/cbi/tblsection.htm

# frpc名称
sed -i 's,发送,Transmission,g' feeds/luci/applications/luci-app-transmission/po/zh_Hans/transmission.po
sed -i 's,frp 服务器,FRP 服务器,g' feeds/luci/applications/luci-app-frps/po/zh_Hans/frps.po
sed -i 's,frp 客户端,FRP 客户端,g' feeds/luci/applications/luci-app-frpc/po/zh_Hans/frpc.po

sed -i 's/\("admin"\), *\("netwizard"\)/\1, "system", \2/g' package/luci-app-netwizard/luasrc/controller/*.lua

# default config
sed -i 's/#aio read size = 0/aio read size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#aio write size = 0/aio write size = 0/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/invalid users = root/#invalid users = root/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/bind interfaces only = yes/bind interfaces only = no/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#create mask/create mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/#directory mask/directory mask/g' feeds/packages/net/samba4/files/smb.conf.template
sed -i 's/0666/0644/g;s/0744/0755/g;s/0777/0755/g' feeds/luci/applications/luci-app-samba4/htdocs/luci-static/resources/view/samba4.js
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/samba.config
sed -i 's/0666/0644/g;s/0777/0755/g' feeds/packages/net/samba4/files/smb.conf.template


sed -i 's/Variable1 = "*.*"/Variable1 = "tudaole"/g' package/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
sed -i 's/Variable2 = "*.*"/Variable2 = "OpenWrt-24.10"/g' package/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
sed -i 's/Variable3 = "*.*"/Variable3 = "x86_64"/g' package/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
sed -i 's/Variable4 = "*.*"/Variable4 = "6.6"/g' package/luci-app-gpsysupgrade/luasrc/model/cbi/gpsysupgrade/sysupgrade.lua
sed -i 's/Variable1 = "*.*"/Variable1 = "oppen321"/g' package/luci-app-gpsysupgrade/root/usr/bin/upgrade.lua
sed -i 's/Variable2 = "*.*"/Variable2 = "OpenWrt-24.10"/g' package/luci-app-gpsysupgrade/root/usr/bin/upgrade.lua
sed -i 's/Variable3 = "*.*"/Variable3 = "x86_64"/g' package/luci-app-gpsysupgrade/root/usr/bin/upgrade.lua
sed -i 's/Variable4 = "*.*"/Variable4 = "6.6"/g' package/luci-app-gpsysupgrade/root/usr/bin/upgrade.lua

# 在线更新配置
echo -n "$(date +'%Y%m%d')" > package/base-files/files/etc/openwrt_version

# 必要的补丁
pushd feeds/luci
    curl -s https://raw.githubusercontent.com/oppen321/path/refs/heads/main/Firewall/0001-luci-mod-status-firewall-disable-legacy-firewall-rul.patch | patch -p1
popd

# NTP
sed -i 's/0.openwrt.pool.ntp.org/ntp1.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/1.openwrt.pool.ntp.org/ntp2.aliyun.com/g' package/base-files/files/bin/config_generate
sed -i 's/2.openwrt.pool.ntp.org/time1.cloud.tencent.com/g' package/base-files/files/bin/config_generate
sed -i 's/3.openwrt.pool.ntp.org/time2.cloud.tencent.com/g' package/base-files/files/bin/config_generate

./scripts/feeds update -a
./scripts/feeds install -a
