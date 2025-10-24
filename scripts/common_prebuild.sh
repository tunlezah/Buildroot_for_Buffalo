#!/bin/bash

[ -f ".firstrun" ] && exit 0

##patch to add sysbench and dependency may need to look into why never merged
wget -nc "https://marc.info/?l=buildroot&m=170021431900448&q=raw" -O "$CONFIG_DIR/../patches/buildroot_add_sysbench.patch" 2>/dev/null
wget -nc "https://marc.info/?l=buildroot&m=170021430500441&q=raw" -O "$CONFIG_DIR/../patches/buildroot_add_ck.patch" 2>/dev/null


##merged at some point
##fix for linux-tools dependency
#wget -nc "https://marc.info/?l=buildroot&m=174765172328890&q=raw" -O "$CONFIG_DIR/../patches/buildroot_linux-tools_dep.patch" 2>/dev/null

##bump zfs version that works with default kernel ver
wget -nc "https://gitlab.com/buildroot.org/buildroot/-/commit/98399d11ff6afe053a052f867bb0610eaacd52a0.patch" -O "$CONFIG_DIR/../patches/buildroot_zfs_2.3.4.patch" 2>/dev/null

###bump of unzip version for GCC 15 etc
#wget -nc "https://marc.info/?l=buildroot&m=175725752612610&q=raw" -O "$CONFIG_DIR/../patches/buildroot_unzip_cmake.patch" 2>/dev/null

##patches I'm working on getting into buildroot project, or someone else already has submitted but hasn't made a release yet
for x in "$CONFIG_DIR"/../patches/buildroot_*.patch
do
  echo "applying $x"
  patch -N -p1 < "$x"
done

##add to config somewhat manually
grep -q BR2_PACKAGE_SYSBENCH "$BR2_CONFIG"
if [ $? -ne 0 ]; then
  echo "BR2_PACKAGE_CK_ARCH_SUPPORTS=y" >> "$BR2_CONFIG"
  echo "BR2_PACKAGE_CK=y" >> "$BR2_CONFIG"
  echo "BR2_PACKAGE_SYSBENCH_ARCH_SUPPORTS=y" >> "$BR2_CONFIG"
  echo "BR2_PACKAGE_SYSBENCH=y" >> "$BR2_CONFIG"
fi

##if we are configured to use syslinux mbr set the gpt option, workaround for adding config after config phase
grep -q "BR2_TARGET_SYSLINUX_MBR=y" "$BR2_CONFIG"
if [ $? -eq 0 ]; then
  grep -q "BR2_TARGET_SYSLINUX_GPT" "$BR2_CONFIG"
  if [ $? -ne 0 ]; then
    echo "BR2_TARGET_SYSLINUX_GPT=y" >> "$BR2_CONFIG"
  fi
fi

##try to ensure any config related changes get processed properly
make oldconfig
touch ".firstrun"
echo "Buildroot patches applied, please run make again"
exit 1
