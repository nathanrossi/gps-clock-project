#!/usr/bin/env python3

import sys
import math

def mattranspose(a):
	r = []
	for i in range(len(a[0])):
		row = []
		for j in range(len(a)):
			row.append(a[j][i])
		r.append(row)
	return r

def matmul(a, b):
	n = len(a) # a rows
	ca = len(a[0]) # a cols
	cb = len(b) # b rows
	p = len(b[0]) # b cols
	r = []

	if ca != cb:
		raise Exception("Cannot multiply")

	for i in range(n):
		row = []
		for j in range(p):
			v = 0
			for x in range(ca):
				v += a[i][x] * b[x][j]
			row.append(v)
		r.append(row)
	return r

# matrix values sourced from Wikipedia (https://en.wikipedia.org/wiki/SRGB)
e_matrix = [
		[3.2406, -1.5372, -0.4986],
		[-0.9689, 1.8758, 0.0415],
		[0.0557, -0.2040, 1.0570],
		]

d_matrix = [
		[0.4124, 0.3576, 0.1805],
		[0.2126, 0.7152, 0.0722],
		[0.0193, 0.1192, 0.9505],
		]

def srgb_encode(r, g, b):
	def clinear(c):
		if c <= 0.0031308:
			return 12.92 * c
		else:
			a = 0.055
			return ((1 + a) * (c ** (1/2.4))) - a
	m = [[clinear(r)], [clinear(g)], [clinear(b)]]
	v = matmul(e_matrix, m)
	return (v[0][0], v[1][0], v[2][0])

def srgb_decode(r, g, b):
	def clinear(c):
		if c <= 0.04045:
			return c / 12.92
		else:
			a = 0.055
			return ((c + a) / (1 + a)) ** 2.4
	m = [[clinear(r)], [clinear(g)], [clinear(b)]]
	v = matmul(d_matrix, m)
	return (v[0][0], v[1][0], v[2][0])

if __name__ == "__main__":
	gamma = 2.2
	inbits = 8
	outbits = int(sys.argv[1]) if len(sys.argv) >= 1 else 8
	outbitshex = (1 if (outbits % 4) != 0 else 0) + (outbits / 4)

	insize = (2 ** inbits) - 1
	outsize = (2 ** outbits) - 1

	for a in range(insize + 1):
		v = min(outsize, int(outsize * (float(a) / insize) ** (gamma)))
		print(("%%0%dx" % (outbitshex)) % v)

	# print("simple total memory needed = %d B" % ((insize) * outbits / 8))
	# print("sRGB total memory needed = %d B" % ((insize ** 3) * outbits / 8))

	# TODO: look at 3D LUT with interpolation? might be too much logic for the HX1K.
	# for r in range(insize + 1):
		# for g in range(insize + 1):
			# for b in range(insize + 1):
				# rgb = srgb_decode((float(r) / insize), (float(g) / insize), (float(b) / insize))
				# lrgb = (outsize * rgb[0], outsize * rgb[1], outsize * rgb[2])
				# testv2 = outsize * (float(r) / insize) ** (2.2)
				# print("%s: %s %d " % (repr((r, g, b)), repr(lrgb), testv2))


