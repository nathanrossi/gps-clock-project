#!/bin/bash

# load if not already loaded
modprobe libcomposite

cd /sys/kernel/config/usb_gadget/
mkdir -p debugif
cd debugif

# Setup the usb descriptors
echo -n 0x1d6b > idVendor # Linux Foundation
echo -n 0x0104 > idProduct # Multifunction Composite Gadget
echo -n 0x0100 > bcdDevice # v1.0.0
echo -n 0x0200 > bcdUSB # USB 2.0

mkdir -p strings/0x409
echo -n "fedcba9876543210" > strings/0x409/serialnumber
echo -n "Nathan Rossi" > strings/0x409/manufacturer
echo -n "RaspberryPi Zero" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo -n "Config 1: ECM Network" > configs/c.1/strings/0x409/configuration
echo -n 250 > configs/c.1/MaxPower

# gadget functions

# serial
mkdir -p functions/acm.usb0
ln -s functions/acm.usb0 configs/c.1/

# ethernet (random host/dev addrs)
mkdir -p functions/ecm.usb0
#echo "48:6f:73:74:50:43" > functions/ecm.usb0/host_addr
#echo "42:61:64:55:53:42" > functions/ecm.usb0/dev_addr
ln -s functions/ecm.usb0 configs/c.1/
ls /sys/class/udc > UDC

