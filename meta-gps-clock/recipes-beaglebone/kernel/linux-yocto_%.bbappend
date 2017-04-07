
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI_append_beaglebone = " \
		file://spidev.cfg \
		"

