#!/usr/bin/env python

# scp gpio-led-screen.py 10.0.0.110:~/ && ssh 10.0.0.110 scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no gpio-led-screen.py root@10.0.10.88:~/
# scpnk -oProxyCommand="ssh -W %h:%p 10.0.0.110" uImage-zynq-zybo.dtb root@10.0.10.88:~/
# scpnk -oProxyCommand="ssh -W %h:%p 10.0.0.110" gpio-led-screen.py root@10.0.10.88:~/

import os
import sys
import time

def quickfilerw(path, write = None):
	if os.path.exists(path):
		if write != None:
			# print("writing to '%s' = %s" % (path, repr(write)))
			with open(path, "wb") as f:
				f.write(write)
				return True
		else:
			with open(path, "rb") as f:
				read = f.read().strip("\n")
			# print("reading fromt '%s' = %s" % (path, repr(read)))
			return read
	raise Exception("File does not exist")

class GpioPin:
	__sysfsroot__ = os.path.join("/sys", "class", "gpio")

	@staticmethod
	def __chip__(label):
		for i in os.listdir(GpioPin.__sysfsroot__):
			abspath = os.path.join(GpioPin.__sysfsroot__, i)
			# print("looking at %s" % i)
			if os.path.isdir(abspath) and i.startswith("gpiochip"):
				labelpath = os.path.join(abspath, "label")
				# print("labelpath = %s" % labelpath)
				if os.path.exists(labelpath):
					labelname = quickfilerw(labelpath)
					# print("labelname == %s ?== %s" % (label, labelname))
					if labelname == label:
						return abspath
		return None

	@staticmethod
	def chippin(label, pin):
		chippath = GpioPin.__chip__(label)
		if chippath == None:
			return None

		count = int(quickfilerw(os.path.join(chippath, "ngpio")))
		base = int(quickfilerw(os.path.join(chippath, "base")))

		if pin >= 0 and pin < count:
			# print("pin %d, sys index = %d" % (pin, base + pin))
			return GpioPin(base + pin)
		raise Exception("Pin out of bounds for chip '%s' (total pins %d)" % (label, count))

	def __init__(self, index):
		self.path = os.path.join(GpioPin.__sysfsroot__, "gpio%d" % index)
		self.index = index

	def __export__(self):
		if not os.path.exists(self.path):
			quickfilerw(os.path.join(GpioPin.__sysfsroot__, "export"), "%d" % self.index)

	def dir(self, output = True):
		self.__export__()
		dirpath = os.path.join(self.path, "direction")
		if dirpath and os.path.exists(dirpath):
			return quickfilerw(dirpath, "out" if output else "in")
		return False

	def set(self, value = None):
		self.__export__()
		path = os.path.join(self.path, "value")
		if path and os.path.exists(path):
			return quickfilerw(path, "%d" % value if value != None else None)
		return False

	def get(self):
		return self.set(None)

def setrow(index):
	print("setrow = %d" % index)
	a0.set(index & (1 << 0))
	a1.set(index & (1 << 1))
	a2.set(index & (1 << 2))

if __name__ == "__main__":
	jf = [None, 13, 10, 11, 12, None, None, 0, 9, 14, 15]

	clk = GpioPin.chippin("zynq_gpio", jf[1])
	lat = GpioPin.chippin("zynq_gpio", jf[2])
	oe = GpioPin.chippin("zynq_gpio", jf[3])

	a0 = GpioPin.chippin("zynq_gpio", jf[4]) # wrong?
	# a0 = GpioPin.chippin("zynq_gpio", jf[7])
	# a1 = GpioPin.chippin("zynq_gpio", jf[8])
	# a2 = GpioPin.chippin("zynq_gpio", jf[9])

	# r1 = GpioPin.chippin("zynq_gpio", jf[4])
	# g1 = GpioPin.chippin("zynq_gpio", 0)
	# b1 = GpioPin.chippin("zynq_gpio", 14)

	clk.dir(True)
	lat.dir(True)
	oe.dir(True)
	a0.dir(True)

	clk.set(0)
	lat.set(0)
	oe.set(0)
	a0.set(0)

	n = 0
	while True:
		oe.set(1)
		lat.set(0)
		clk.set(0)

		a0.set(n)
		n += 1
		if n > 1:
			n = 0

		# row,

		for i in range(32):
			clk.set(1)
			# time.sleep(0.01)
			clk.set(0)
			# time.sleep(0.01)

		time.sleep(0.001)

		lat.set(1)
		time.sleep(0.001)
		lat.set(0)

		# time.sleep(0.01)
		time.sleep(0.001)

		a0.set(0)
		oe.set(0)

		time.sleep(1)
		# time.sleep(1)
		# time.sleep(0.1)

