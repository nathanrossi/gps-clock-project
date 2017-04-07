SUMMARY = "The GPS Clock base image"

IMAGE_INSTALL = " \
		packagegroup-core-boot \
		${CORE_IMAGE_EXTRA_INSTALL} \
		\
		gpsd gps-utils gpsd-gpsctl \
		python3 python3-modules \
		python3-spidev \
		i2c-tools \
		usbutils \
		device-tree \
		"

# debugging tools/modules/stuff

IMAGE_INSTALL += " \
		util-linux e2fsprogs \
		ethtool \
		packagegroup-core-ssh-openssh \
		"

# Limit python modules to those used?

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

