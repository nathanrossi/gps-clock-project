SUMMARY = "The GPS Clock base image"

IMAGE_INSTALL = " \
		packagegroup-core-boot \
		${ROOTFS_PKGMANAGE_BOOTSTRAP} \
		${CORE_IMAGE_EXTRA_INSTALL} \
		\
		gpsd gps-utils gpsd-gpsctl \
		python3 python3-modules \
		i2c-tools \
		usbutils \
		"

# Limit python modules to those used?

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

