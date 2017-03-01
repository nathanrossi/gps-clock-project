
do_deploy_append () {
	# Enable 'dwc2' overlay for USB
	if [ "${ENABLE_DWC2}" = "1" ]; then
		echo "# Enable dwc2 overlay" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
		echo "dtoverlay=dwc2" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
	fi

	if [ -n "${INITRAMFS_IMAGE}" ]; then
		sed -i "s/#initramfs.*/initramfs ${INITRAMFS_IMAGE}.cpio.gz 0x00800000/" ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
	fi
}

