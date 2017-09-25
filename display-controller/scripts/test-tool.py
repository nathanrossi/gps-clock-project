#!/usr/bin/env python3

import os
import termios
from PIL import Image

def serial(path, baud = 115200, bits = 8, parity = False, oddparity = False, stopbits = 1, local = True, crtscts = False, blocking = True):
	fd = os.open(path, os.O_RDWR | os.O_NOCTTY | (os.O_NONBLOCK if not blocking else 0))
	if fd == -1:
		raise Exception("Opening device '%s' failed" % path)

	current = termios.tcgetattr(fd)
	# ignore break,  don't translate \r -> \n
	current[0] |= termios.IGNBRK
	current[0] &= ~(termios.ICRNL | termios.BRKINT | termios.IMAXBEL)
	# disable OPOST
	current[1] &= ~termios.OPOST
	# disable \n -> \r
	current[1] &= ~termios.ONLCR
	# disable echo
	current[3] &= ~(termios.ECHO | termios.ECHOE | termios.ECHOK | termios.ECHOCTL)
	# enable 'cbreak'
	current[3] &= ~termios.ICANON
	# disable signals
	current[3] &= ~termios.ISIG

	termios.tcflush(fd, termios.TCIFLUSH)
	termios.tcsetattr(fd, termios.TCSANOW, current)
	current = termios.tcgetattr(fd)

	# baud rate
	if not(stopbits == 1 or stopbits == 2):
		raise Exception("Invalid number of stop bits (only 1 or 2 is valid).")
	current[2] = (current[2] & ~termios.CSTOPB) | (termios.CSTOPB if stopbits == 2 else 0)
	current[2] = (current[2] & ~termios.PARENB) | (termios.PARENB if parity else 0)
	current[2] = (current[2] & ~termios.PARODD) | (termios.PARODD if oddparity else 0)

	# get speed_t value
	new_speed = None
	if "B%d" % baud in termios.__dict__:
		new_speed = termios.__dict__["B%d" % baud]
	if new_speed is None:
		raise Exception("Invalid baud rate '%d'" % baud)
	current[4] = new_speed
	current[5] = new_speed

	termios.tcflush(fd, termios.TCIFLUSH)
	termios.tcsetattr(fd, termios.TCSANOW, current)
	current = termios.tcgetattr(fd)

	# flow
	current[2] = (current[2] & ~termios.CLOCAL) | (termios.CLOCAL if local else 0)
	current[2] = (current[2] & ~termios.CRTSCTS) | (termios.CRTSCTS if crtscts else 0)

	termios.tcflush(fd, termios.TCIFLUSH)
	termios.tcsetattr(fd, termios.TCSANOW, current)

	return fd

def bit_color_pattern(ofunc):
	# empty image
	image = []
	for i in range(32):
		column = []
		for j in range(16):
			column.append((0,0,0))
		image.append(column)

	xoff = 0
	yoff = 0
	colour = 0
	while True:
		xoff += 1
		if xoff >= 32:
			xoff = 0
			yoff += 1
			if yoff >= 16:
				yoff = 0
				colour += 1
				if colour >= 3:
					colour = 0

		for i in range(32):
			for j in range(16):
				if j == yoff or i == xoff:
					image[i][j] = (
							0x3f if colour == 0 else 0,
							0x3f if colour == 1 else 0,
							0x3f if colour == 2 else 0,
							)
				else:
					image[i][j] = (0, 0, 0)

		ofunc(image)

def color(ofunc, color = None):
	# empty image
	image = []
	for i in range(32):
		column = []
		for j in range(16):
			column.append(color or (0x00, 0x00, 0x00))
		image.append(column)
	ofunc(image)

def icon(ofunc):
	img = Image.open("linux-penguin.png")
	ipx = img.load()
	image = []
	for i in range(32):
		column = []
		for j in range(16):
			apx = [f / 4 for f in ipx[i % 16, j]]
			npx = (int((apx[0] ** 2) / 256), int((apx[1] ** 2) / 256), int((apx[2] ** 2) / 256))
			column.append(npx)
		image.append(column)
	ofunc(image)

if __name__ == "__main__":
	print("test color patterns on display")

	sfd = serial("/dev/ttyUSB1", baud = 115200)

	def write_frame(frame, segs = 2):
		total = 0
		for i in range(8):
			out = [0xf0 + (i & 0xf)]
			m = i % 8 # handle row 0 twice
			for j in range(32):
				for z in range(segs)[::-1]:
					for c in range(3)[::-1]:
						out.append(frame[j][m + (8 * z)][c])
			os.write(sfd, bytearray(out))
			total += len(out)
		out = [0x10]
		total += 1
		os.write(sfd, bytearray(out))
		print("wrote frame")
		print("wait for flip")
		b = os.read(sfd, 1)
		if b[0] == 0xe0:
			print("flip complete")

	# bit_color_pattern(write_frame)
	# color(write_frame, color = (0, 0, 0))
	icon(write_frame)

	os.close(sfd)

