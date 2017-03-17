#!/usr/bin/env python3

import os
import sys

while True:
	b = sys.stdin.buffer.read(3)
	if len(b) == 0:
		break

	print("%02x%02x%02x" % (b[0], b[1], b[2]))

