
do_deploy_append () {
	# Enable 'dwc2' overlay for USB
	if [ "${ENABLE_DWC2}" = "1" ]; then
		echo "# Enable dwc2 overlay" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
		echo "dtoverlay=dwc2" >> ${DEPLOYDIR}/bcm2835-bootfiles/config.txt
	fi
}

