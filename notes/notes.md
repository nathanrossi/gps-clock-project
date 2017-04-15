
LED Panel Info
==============

Medium 16x32 RGB LED matrix - https://www.adafruit.com/products/420

Pinouts
-------
https://learn.adafruit.com/32x16-32x32-rgb-led-matrix/new-wiring

Internal Diagrams/Behaviour
---------------------------
https://web.archive.org/web/20121201205905/http://www.hobbypcb.com/blog/item/3-16x32-rgb-led-matrix-technical-details.html

http://pdf.datasheetcatalog.com/datasheet/toshiba/3889.pdf
http://www.limpkin.fr/public/RGB_Matrix/JXI5020.pdf
https://web.archive.org/web/20141008072416/http://www.bjtopspace.com/ziliao/CYT62726.pdf
http://www.nxp.com/documents/data_sheet/74HC_HCT138.pdf

Code Samples
------------
https://developer.mbed.org/users/RRacer/code/Adafruit-16x32-basic-demo/docs/tip/main_8cpp_source.html


GPSD
====

`gpsd -D 5 -N -n /dev/ttyAMA0`
`GPSD_UNITS=metric cgps`

http://www.catb.org/gpsd/gpsd-time-service-howto.html


GPIO sysfs
==========

http://elinux.org/GPIO
https://www.kernel.org/doc/Documentation/gpio/sysfs.txt
https://www.kernel.org/doc/Documentation/devicetree/bindings/pinctrl/pinctrl-bindings.txt


USB Gadget Interface
====================

https://pinout.xyz/pinout/uart
http://isticktoit.net/?p=1383
http://vinizlinux.blogspot.com.au/2014/12/configuring-network-bridge-using-nmcli.html

Below is a configfs setup for a Serial + Ethernet Gadget Device. Easier to just
use the CDC ACM+ETH module.

```
[Unit]
Description=Setup USB Gadget Devices
DefaultDependencies=no
After=local-fs.target
Before=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/etc/setup-usb-gadgets.sh

[Install]
WantedBy=network.target
```


```
#!/bin/bash

cd /sys/kernel/config/usb_gadget/
mkdir -p pizero
cd pizero

# Setup the usb descriptors
echo 0x1d6b > idVendor # Linux Foundation
echo 0x0104 > idProduct # Multifunction Composite Gadget
echo 0x0100 > bcdDevice # v1.0.0
echo 0x0200 > bcdUSB # USB 2.0

mkdir -p strings/0x409
echo "fedcba9876543210" > strings/0x409/serialnumber
echo "Nathan Rossi" > strings/0x409/manufacturer
echo "RaspberryPi Zero" > strings/0x409/product

mkdir -p configs/c.1/strings/0x409
echo "Config 1: ECM Network" > configs/c.1/strings/0x409/configuration
echo 250 > configs/c.1/MaxPower

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

```
