DESCRIPTION = "Setup a USB Debug Interface Gadget"
SECTION = "bsp"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

RDEPENDS_${PN} = "bash"

# kernel modules used for configfs setup
RRECOMMENDS_${PN} += " \
		kernel-module-libcomposite \
		kernel-module-usb-f-serial \
		kernel-module-usb-u-ether \
		kernel-module-usb-f-acm \
		kernel-module-usb-f-ecm \
		"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = " \
		file://usb-gadget-debugif.sh \
		file://usb-gadget-debugif.service \
		"

#inherit update-rc.d

#INITSCRIPT_NAME = "usb-gadget-debugif"
#INITSCRIPT_PARAMS = "start 10 S . stop 10 0 6 1 ."

inherit systemd

SYSTEMD_AUTO_ENABLE_${PN} = "enable"
SYSTEMD_SERVICE_${PN} = "usb-gadget-debugif.service"

S = "${WORKDIR}"

do_compile () {
	:
}

do_install () {
	install -Dm755 ${WORKDIR}/usb-gadget-debugif.sh ${D}${sysconfdir}/usb-gadget-debugif.sh
	install -Dm0644 ${WORKDIR}/usb-gadget-debugif.service ${D}${systemd_system_unitdir}/usb-gadget-debugif.service
}

