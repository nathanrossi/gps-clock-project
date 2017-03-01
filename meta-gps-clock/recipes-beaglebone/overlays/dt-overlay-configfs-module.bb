LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

inherit module

FILESEXTRAPATHS_prepend := "${THISDIR}/dt-overlay-configfs:"
SRC_URI = " \
		file://Makefile \
		file://dt-overlay-configfs.c \
		"

S = "${WORKDIR}"

