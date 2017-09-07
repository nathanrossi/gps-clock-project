DESCRIPTION = ""
HOMEPAGE = ""
LICENSE = "MIT"
SECTION = "bsp"

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

INHIBIT_DEFAULT_DEPS = "1"
DEPENDS = "yosys-native arachne-pnr-native icestorm-native"

# use source from local repo
SOURCE_BASE := "${THISDIR}/../../../display-controller"

B = "${S}"

export YOSYS = "${STAGING_DIR_NATIVE}${bindir_native}/yosys"
export ARACHNEPNR = "${STAGING_DIR_NATIVE}${bindir_native}/arachne-pnr"
export ICEPACK = "${STAGING_DIR_NATIVE}${bindir_native}/icepack"
export ICETIME = "${STAGING_DIR_NATIVE}${bindir_native}/icetime"
export ICEPLL = "${STAGING_DIR_NATIVE}${bindir_native}/icepll"
export ICEBOX = "${STAGING_DIR_NATIVE}${datadir_native}/icebox"

do_unpack () {
	# clone the source
	rm -rf ${S}/*
	cp -ar ${SOURCE_BASE}/* ${S}/
}

do_compile () {
	oe_runmake V=1 bitstream
}

inherit deploy
do_deploy () {
	install -Dm 0644 ${S}/obj/top.bin ${DEPLOYDIR}/top.bin
}
addtask deploy before do_build after do_install

