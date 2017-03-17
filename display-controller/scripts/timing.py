#!/usr/bin/env python3

import os
import sys
import math

f_base = 12000000

cols = 32
rows = 8
pixelcycles = 256
hold = 32

# BBB Ppx32 Ll Ox32 C
states = 3 + (32 * 2) + 2 + (32) + 1
ontime = float(32) / states

cycles_r = states
cycles_c = cycles_r * rows
cycles_f = cycles_c * pixelcycles

print("F = %d Hz" % f_base)
print("Cycles for Row = %d cycles" % cycles_r)
print("Cycles for Cycle = %d cycles" % cycles_c)
print("Cycles for Frame = %d cycles" % cycles_f)

rrate = float(f_base) / cycles_f

print("Vert Hz = %d Hz" % rrate)

onrowtime = ontime / rows
print("On time per pixel = %.2f %%" % (onrowtime * 100))

# BBB (Ppx32 Ll) * cycles + (~Ppx32 + Ll cycles) C
states = 3 + ((pixelcycles + 1) * (32 * 2)) + 2 + 1
ontime = (pixelcycles * (float(32 * 2))) / states

cycles_r = states
cycles_f = cycles_r * rows

print("F = %d Hz" % f_base)
print("Cycles for Row = %d cycles" % cycles_r)
print("Cycles for Frame = %d cycles" % cycles_f)

rrate = float(f_base) / cycles_f

print("Vert Hz = %d Hz" % rrate)

onrowtime = ontime / rows
print("On time per pixel = %.2f %%" % (onrowtime * 100))


# BBB (Ppx32 Ll) * cycles + (~Ppx32 + Ll cycles) C
states = 3 + ((pixelcycles + 1) * (32 * 2)) + 2 + 1
ontime = (pixelcycles * (float(32 * 2))) / states

cycles_r = states
cycles_f = cycles_r * rows

print("F = %d Hz" % f_base)
print("Cycles for Row = %d cycles" % cycles_r)
print("Cycles for Frame = %d cycles" % cycles_f)

rrate = float(f_base) / cycles_f

print("Vert Hz = %d Hz" % rrate)

onrowtime = ontime / rows
print("On time per pixel = %.2f %%" % (onrowtime * 100))

