
inherit devicetree

COMPATIBLE_MACHINE_beaglebone-yocto = ".*"
SRC_URI_beaglebone-yocto = " \
		file://am335x-bone-gps-clock.dts \
		file://uart-test.dts \
		"

SRC_URI_raspberrypi0 = "file://bcm2835-rpi-zero-gps-clock.dts"

