#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_file"/. /
cp -avf "/ctx/Mtk79ICAP"/. /tmp/mtk79
### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# this installs a package from fedora repos
#dnf5 install -y tmux

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

#systemctl enable podman.socket


#### Kernel image

cd /tmp/mtk79

KERNELVER=$(skopeo inspect docker://ghcr.io/ublue-os/bazzite-nvidia-open:stable | grep ostree.linux | sed 's/^.*: "\(.*\)",$/\1/')

make -j"$(nproc)" -C /lib/modules/$KERNELVER/build M=$PWD/driver modules \
  KCFLAGS="-include linux/version.h -include $PWD/driver/compat-mt7921.h" \
  CONFIG_MT76_USB=m CONFIG_MT76_CONNAC_LIB=m CONFIG_MT792x_LIB=m CONFIG_MT792x_USB=m \
  CONFIG_MT7921_COMMON=m CONFIG_MT7921U=m \
  CONFIG_MT76_SDIO= CONFIG_MT76x02_LIB= CONFIG_MT76x02_USB= CONFIG_MT76x0_COMMON= \
  CONFIG_MT76x2_COMMON= CONFIG_MT7603E= CONFIG_MT7615_COMMON= CONFIG_MT7915E= \
  CONFIG_MT7996E= CONFIG_MT7925_COMMON= CONFIG_MT7921E= CONFIG_MT7921S= CONFIG_MT76_NPU=
make -C /lib/modules/$KERNELVER/build M=$PWD/driver INSTALL_MOD_DIR=updates modules_install
depmod -a $KERNELVER

echo "options mt7921_common iq_dense=1 iq_ring_kb=256" > /etc/modprobe.d/mt7921-iq.conf
echo "options mt76_usb rx_urbs=512" >> /etc/modprobe.d/mt7921-iq.conf
