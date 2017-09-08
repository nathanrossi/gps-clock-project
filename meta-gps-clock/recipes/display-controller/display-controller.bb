DESCRIPTION = ""
HOMEPAGE = ""
LICENSE = "MIT"
SECTION = "bsp"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit localsrc

PACKAGE_ARCH = "${MACHINE_ARCH}"

# build directory
B = "${WORKDIR}/${BPN}"

INHIBIT_DEFAULT_DEPS = "1"
DEPENDS = "yosys-native arachne-pnr-native icestorm-native icarus-verilog-native"

export IVERILOG = "${STAGING_DIR_NATIVE}${bindir_native}/iverilog -B${STAGING_DIR_NATIVE}${libdir_native}/ivl"
export VVP = "${STAGING_DIR_NATIVE}${bindir_native}/vvp -M${STAGING_DIR_NATIVE}${libdir_native}/ivl"
export ICEBOX = "${STAGING_DIR_NATIVE}${datadir_native}/icebox"

do_compile () {
	oe_runmake -f ${S}/Makefile S="${S}" O="${B}" V=1 bitstream
}

inherit deploy
do_deploy () {
	install -Dm 0644 ${B}/top.bin ${DEPLOYDIR}/top.bin
}
addtask deploy before do_build after do_install

do_check () {
	oe_runmake -f ${S}/Makefile S="${S}" O="${B}" V=2 tests
}
addtask check after do_compile

