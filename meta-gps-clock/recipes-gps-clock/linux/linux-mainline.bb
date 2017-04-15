SECTION = "kernel"
DESCRIPTION = "Linux Kernel (torvalds)"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=d7810fab7487fb0aad327b76f1be7cd7"

inherit kernel
require recipes-kernel/linux/linux-dtb.inc

DEFAULT_PREFERENCE = "-1"

S = "${WORKDIR}/git"

BRANCH ?= "master"

SRCREV = "${AUTOREV}"
PV = "0.0.0+${BRANCH}+${SRCPV}"
SRC_URI = "git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git;protocol=https;branch=${BRANCH}"

# ignore this recipe unless explicitly using it
python () {
    if d.getVar("PREFERRED_PROVIDER_virtual/kernel", True) != d.getVar("PN", True):
        d.delVar("BB_DONT_CACHE")
        raise bb.parse.SkipPackage("Set PREFERRED_PROVIDER_virtual/kernel to %s to enable it" % (d.getVar("PN", True)))
}

# force the use of DEFAULT_CONFIG
BCONFIG = "${B}/.config"
kernel_do_configure_prepend() {
	cp ${S}/arch/${ARCH}/configs/${DEFAULT_CONFIG} ${BCONFIG}

	# spidev
	echo "CONFIG_SPI_SPIDEV=y" >> ${BCONFIG}

	# otg mode does not switch automatically (TODO: sort that out)
	echo "CONFIG_USB_DWC2_PERIPHERAL=y" >> ${BCONFIG}
	#echo "CONFIG_USB_DWC2_DEBUG=y" >> ${BCONFIG}
	#echo "CONFIG_USB_DWC2_VERBOSE=y" >> ${BCONFIG}
	echo "CONFIG_USB_GADGET_VBUS_DRAW=500" >> ${BCONFIG}

	# usb gadgetfs
	echo "CONFIG_USB_GADGET=y" >> ${BCONFIG}

	#echo "CONFIG_USB_LIBCOMPOSITE=y" >> ${BCONFIG}

	#echo "CONFIG_USB_F_ACM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_U_SERIAL=y" >> ${BCONFIG}
	#echo "CONFIG_USB_U_ETHER=y" >> ${BCONFIG}
	#echo "CONFIG_USB_F_SERIAL=y" >> ${BCONFIG}
	#echo "CONFIG_USB_F_NCM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_F_ECM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_F_EEM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_F_SUBSET=y" >> ${BCONFIG}

	#echo "CONFIG_USB_CONFIGFS=y" >> ${BCONFIG}
	#echo "CONFIG_USB_CONFIGFS_SERIAL=y" >> ${BCONFIG}
	#echo "CONFIG_USB_CONFIGFS_ACM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_CONFIGFS_OBEX=y" >> ${BCONFIG}
	#echo "CONFIG_USB_CONFIGFS_NCM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_CONFIGFS_ECM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_CONFIGFS_ECM_SUBSET=y" >> ${BCONFIG}

	# legacy gadgets
	#echo "CONFIG_MODULES=y" >> ${BCONFIG}
	#echo "CONFIG_USB_ETH=n" >> ${BCONFIG}
	#echo "CONFIG_USB_ETH_RNDIS=y" >> ${BCONFIG}
	#echo "CONFIG_USB_ETH_EEM=y" >> ${BCONFIG}
	#echo "CONFIG_USB_G_SERIAL=m" >> ${BCONFIG}
	echo "CONFIG_USB_CDC_COMPOSITE=y" >> ${BCONFIG}
	#echo "CONFIG_USB_G_MULTI=y" >> ${BCONFIG}
	#echo "CONFIG_USB_G_MULTI_RNDIS=y" >> ${BCONFIG}
	#echo "CONFIG_USB_G_MULTI_CDC=y" >> ${BCONFIG}

	cat ${BCONFIG}
}

COMPATIBLE_MACHINE = "^$"

DEFAULT_CONFIG_armv7a = "multi_v7_defconfig"

# raspberry pi (B, zero)
COMPATIBLE_MACHINE_raspberrypi = "raspberrypi$"
DEFAULT_CONFIG_raspberrypi = "bcm2835_defconfig"
KERNEL_DEVICETREE_raspberrypi = "bcm2835-rpi-b.dtb"
KERNEL_DEVICETREE_raspberrypi0 = "bcm2835-rpi-zero.dtb"

