#!/usr/bin/env python

import os
import sys
import spidev
import time
import datetime

font = {
		"A" : [ [0, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[1, 1, 1, 1, 1],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 0, 0, 0, 0]],
		"B" : [ [1, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[1, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[1, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],

		"0" : [ [0, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 1, 1],
				[1, 0, 1, 0, 1],
				[1, 1, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],
		"1" : [ [0, 0, 1, 0, 0],
				[0, 1, 1, 0, 0],
				[0, 0, 1, 0, 0],
				[0, 0, 1, 0, 0],
				[0, 0, 1, 0, 0],
				[0, 0, 1, 0, 0],
				[0, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],
		"2" : [ [0, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[0, 0, 0, 0, 1],
				[0, 0, 0, 1, 0],
				[0, 0, 1, 0, 0],
				[0, 1, 0, 0, 0],
				[1, 1, 1, 1, 1],
				[0, 0, 0, 0, 0]],
		"3" : [ [1, 1, 1, 1, 1],
				[0, 0, 0, 1, 0],
				[0, 0, 1, 0, 0],
				[0, 0, 0, 1, 0],
				[0, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],
		"4" : [ [0, 0, 0, 1, 0],
				[0, 0, 1, 1, 0],
				[0, 1, 0, 1, 0],
				[1, 0, 0, 1, 0],
				[1, 1, 1, 1, 1],
				[0, 0, 0, 1, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0]],
		"5" : [ [1, 1, 1, 1, 1],
				[1, 0, 0, 0, 0],
				[1, 1, 1, 1, 0],
				[0, 0, 0, 0, 1],
				[0, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],
		"6" : [ [0, 0, 1, 1, 0],
				[0, 1, 0, 0, 0],
				[1, 0, 0, 0, 0],
				[1, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],
		"7" : [ [1, 1, 1, 1, 1],
				[0, 0, 0, 0, 1],
				[0, 0, 0, 1, 0],
				[0, 0, 1, 0, 0],
				[0, 1, 0, 0, 0],
				[0, 1, 0, 0, 0],
				[0, 1, 0, 0, 0],
				[0, 0, 0, 0, 0]],
		"8" : [ [0, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 0],
				[0, 0, 0, 0, 0]],
		"9" : [ [0, 1, 1, 1, 0],
				[1, 0, 0, 0, 1],
				[1, 0, 0, 0, 1],
				[0, 1, 1, 1, 1],
				[0, 0, 0, 0, 1],
				[0, 0, 0, 1, 0],
				[0, 1, 1, 0, 0],
				[0, 0, 0, 0, 0]],
		" " : [ [0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0],
				[0, 0, 0, 0, 0]],
		":" : [ [0, 0, 0, 0],
				[0, 1, 1, 0],
				[0, 1, 1, 0],
				[0, 0, 0, 0],
				[0, 1, 1, 0],
				[0, 1, 1, 0],
				[0, 0, 0, 0],
				[0, 0, 0, 0]],
	}

font_small = {
		"0" : [ [0,1,1,0],
				[1,0,0,1],
				[1,0,0,1],
				[1,0,0,1],
				[0,1,1,0]],
		"1" : [ [0,0,1,0],
				[0,0,1,0],
				[0,0,1,0],
				[0,0,1,0],
				[0,0,1,0]],
		"2" : [ [1,1,1,0],
				[0,0,0,1],
				[0,1,1,0],
				[1,0,0,0],
				[1,1,1,1]],
		"3" : [ [1,1,1,0],
				[0,0,0,1],
				[0,1,1,0],
				[0,0,0,1],
				[1,1,1,1]],
		"4" : [ [1,0,0,1],
				[1,0,0,1],
				[1,1,1,1],
				[0,0,0,1],
				[0,0,0,1]],
		"5" : [ [1,1,1,1],
				[1,0,0,0],
				[1,1,1,1],
				[0,0,0,1],
				[1,1,1,1]],
		"6" : [ [1,1,1,0],
				[1,0,0,0],
				[1,1,1,1],
				[1,0,0,1],
				[1,1,1,1]],
		"7" : [ [1,1,1,1],
				[0,0,0,1],
				[0,0,0,1],
				[0,0,0,1],
				[0,0,0,1]],
		"8" : [ [0,1,1,0],
				[1,0,0,1],
				[0,1,1,0],
				[1,0,0,1],
				[0,1,1,0]],
		"9" : [ [0,1,1,0],
				[1,0,0,1],
				[0,1,1,1],
				[0,0,0,1],
				[0,1,1,0]],
		":" : [ [0],
				[1],
				[0],
				[1],
				[0]],
		" " : [ [0,0,0,0],
				[0,0,0,0],
				[0,0,0,0],
				[0,0,0,0],
				[0,0,0,0]],
		}


font_smallest = {
		"0" : [ [1,1,1],
				[1,0,1],
				[1,0,1],
				[1,0,1],
				[1,1,1]],
		"1" : [ [0,1,0],
				[1,1,0],
				[0,1,0],
				[0,1,0],
				[0,1,0]],
		"2" : [ [1,1,1],
				[0,0,1],
				[1,1,1],
				[1,0,0],
				[1,1,1]],
		"3" : [ [1,1,1],
				[0,0,1],
				[0,1,1],
				[0,0,1],
				[1,1,1]],
		"4" : [ [1,0,1],
				[1,0,1],
				[1,1,1],
				[0,0,1],
				[0,0,1]],
		"5" : [ [1,1,1],
				[1,0,0],
				[1,1,1],
				[0,0,1],
				[1,1,1]],
		"6" : [ [1,1,1],
				[1,0,0],
				[1,1,1],
				[1,0,1],
				[1,1,1]],
		"7" : [ [1,1,1],
				[0,0,1],
				[0,0,1],
				[0,0,1],
				[0,0,1]],
		"8" : [ [1,1,1],
				[1,0,1],
				[1,1,1],
				[1,0,1],
				[1,1,1]],
		"9" : [ [1,1,1],
				[1,0,1],
				[1,1,1],
				[0,0,1],
				[1,1,1]],
		":" : [ [0],
				[1],
				[0],
				[1],
				[0]],
		" " : [ [0,0,0],
				[0,0,0],
				[0,0,0],
				[0,0,0],
				[0,0,0]],
		}

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
		# time.sleep(0.01)

def line_pattern(ofunc):
	patternlist = []

	print("generating patterns")
	xoff = 0
	yoff = 1
	colour = 0
	while True:
		image = []
		for i in range(32):
			column = []
			for j in range(16):
				if i % yoff == xoff or j % yoff == xoff:
					column.append((
							0x3f if colour == 0 else 0,
							0x3f if colour == 1 else 0,
							0x3f if colour == 2 else 0,
							))
				else:
					column.append((0, 0, 0))
			image.append(column)
		patternlist.append(image)

		xoff += 1
		if xoff >= yoff:
			xoff = 0
			yoff += 1
			if yoff >= 16:
				yoff = 1
				colour += 1
				if colour >= 3:
					colour = 0
					break

	print("looping patterns")
	while True:
		for i in patternlist:
			ofunc(i)
			time.sleep(0.1)

def rainbow(ofunc):
	patternlist = []

	print("generating patterns")
	xoff = 0
	yoff = 0
	colour = 0
	while True:
		image = []
		xsteps = int((xoff / 32))
		for i in range(32):
			column = []
			for j in range(16):
				column.append((
						(xsteps * i) if colour == 0 else 0,
						(xsteps * i) if colour == 1 else 0,
						(xsteps * i) if colour == 2 else 0,
						))
			image.append(column)
		patternlist.append(image)

		xoff += 2
		if xoff >= 256:
			xoff = 0
			colour += 1
			if colour >= 3:
				colour = 0
				break

	print("looping patterns")
	while True:
		for i in patternlist:
			ofunc(i)
			# print(patternlist.index(i))
			# time.sleep(2)

def simplerainbow(ofunc, c):
	image = []
	steps = 32
	for i in range(32):
		column = []
		for j in range(16):
			column.append((
					int(c[0] * i / steps),
					int(c[1] * i / steps),
					int(c[2] * i / steps),
					))
		image.append(column)

	print("looping patterns")
	while True:
		ofunc(image)

def rainbowbroken(ofunc):
	patternlist = []

	print("generating patterns")
	m = 255
	xoff = 0
	yoff = 0
	colour = 0
	while True:
		image = []
		xsteps = int((xoff / 32))
		for i in range(32):
			column = []
			for j in range(16):
				column.append((
						(xsteps * i) if colour == 0 else 0,
						(xsteps * i) if colour == 1 else 0,
						(xsteps * i) if colour == 2 else 0,
						))
			image.append(column)
		patternlist.append(image)

		xoff += 2
		if xoff >= 256:
			m = len(patternlist) - 1
			break
			xoff = 0
			colour += 1
			if colour >= 3:
				colour = 0
				m = len(patternlist) - 1
				break

	print("looping patterns")
	while True:
		ofunc(patternlist[m])

def single_color(ofunc, color):
	image = []

	print("generating patterns")
	for i in range(32):
		column = []
		for j in range(16):
			column.append(color)
		image.append(column)

	print("looping patterns")
	# while True:
	ofunc(image)
	# time.sleep(1)

def text_pattern(ofunc):
	patterns = []

	test = datetime.datetime.now().strftime("%H:%M:%S")
	for i in range(2):
		xoff = 2
		yoff = 8 - int((5 / 2))
		colour = (0x3f, 0, 0)

		image = []
		for i in range(32):
			column = []
			for j in range(16):
				column.append((0,0,0))
			image.append(column)

		for i in test:
			char = font_smallest[i]
			for x in range(len(char[0])):
				for y in range(len(char)):
					r = min(255, char[y][x] * colour[0])
					g = min(255, char[y][x] * colour[1])
					b = min(255, char[y][x] * colour[2])
					# print("%d, %d" % (x + xoff, y + yoff))
					if not ((x + xoff) >= 32 or (y + yoff) >= 16):
						image[x + xoff][y + yoff] = (r, g, b)
			xoff += len(char[0]) + 1 # pad 1 pixel between
		test = test[::-1]

		patterns.append(image)

	while True:
		for i in patterns:
			ofunc(i)
			time.sleep(0.1)

def clock_output(ofunc):
	# empty image
	image = []
	for i in range(32):
		column = []
		for j in range(16):
			column.append((0,0,0))
		image.append(column)

	colourbreathing = 0
	oldtest = ""
	while True:
		# test = datetime.datetime.now().strftime("%H:%M:%S")
		test = datetime.datetime.now().strftime("%H:%M")
		if test != oldtest:
			print(test)
			xoff = 2
			yoff = 8 - int((5 / 2))
			colour = (0, 0x3f, 0)
			for i in test:
				char = font[i]
				# char = font_smallest[i]
				for x in range(len(char[0])):
					for y in range(len(char)):
						r = min(255, char[y][x] * colour[0])
						g = min(255, char[y][x] * colour[1])
						b = min(255, char[y][x] * colour[2])
						# print("%d, %d" % (x + xoff, y + yoff))
						if not ((x + xoff) >= 32 or (y + yoff) >= 16):
							image[x + xoff][y + yoff] = (r, g, b)
				xoff += len(char[0]) + 1 # pad 1 pixel between

			# colourbreathing += 4
			# if colourbreathing == 256:
				# colourbreathing = 0
		oldtest = test

		ofunc(image)
		time.sleep(0.1)


if __name__ == "__main__":
	print("Testing SPI device")

	# The spi controller normally accepts only single continious writes, that
	# needs to change, for now just handle 1K data

	spi = spidev.SpiDev()
	spi.open(1, 0)
	# spi.open(32766, 0)
	spi.mode = 0
	# spi.max_speed_hz = 6000000
	# spi.max_speed_hz = 4000000
	# spi.max_speed_hz = 3000000
	spi.max_speed_hz = 2000000
	# spi.max_speed_hz = 1000000
	# spi.max_speed_hz = 500000
	# spi.max_speed_hz = 10000
	print("running bus at %f MHz" % (spi.max_speed_hz / 1000 / 1000))

	def write_frame(frame, segs = 2):
		stime = datetime.datetime.now()

		total = 0
		errors = 0
		for i in range(9):
			out = [0xf0 + (i & 0xf)]
			m = i % 8 # handle row 0 twice
			for j in range(32):
				for z in range(segs)[::-1]:
					for c in range(3)[::-1]:
						out.append(frame[j][m + (8 * z)][c])
			r = spi.xfer2(out)
			# check for errors
			for t in range(len(out) - 1): # last byte is on another cycle
				if r[t + 1] != out[t]:
					errors += 1

			total += len(out)

		out = [0x10]
		r = spi.xfer2(out)
		total += len(out)

		etime = datetime.datetime.now()
		mbits = ((total * 8) / 1000 / 1000) / (etime - stime).total_seconds()
		framerate = (1 / (etime - stime).total_seconds())
		print("transfered %d bytes. %f mbit/s, %f Hz vert (errors %d)" % (total, mbits, framerate, errors))

	# bit_color_pattern(write_frame)
	# line_pattern(write_frame)
	# rainbow(write_frame)
	# simplerainbow(write_frame, (0xff, 0xff, 0xff))
	# rainbowbroken(write_frame)
	# while True:
		# for v in [0x3f, 0x00, 0x00, 0x1f, 0x00, 0x00, 0x30, 0x00, 0x00, 22, 0x00]:
			# for i in range(10):
				# single_color(write_frame, (v, 0, 0))
			# time.sleep(0.2)
	# single_color(write_frame, (0, 0xff, 0))
	# time.sleep(3)
	# single_color(write_frame, (0, 0, v))
	# time.sleep(3)
	# single_color(write_frame, (v, v, v))
	# text_pattern(write_frame)
	clock_output(write_frame)

	spi.close()

