SECTION = "bsp"
DEPENDS = "dtc-native"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS_prepend := "${THISDIR}:"
SRC_URI = "file://uart-test.dts"

S = "${WORKDIR}"

do_configure() {
	:
}

do_compile() {
	dtc -O dtb -o uart-test.dtbo -b 0 -@ ${S}/uart-test.dts
}

do_install() {
	install -Dm 0644 uart-test.dtbo ${D}/boot/overlays/uart-test.dtbo
}

FILES_${PN} += "/boot/overlays/*"

