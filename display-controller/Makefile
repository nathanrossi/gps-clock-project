
BASEPROGS=/home/nathan/fpga-ice40
YOSYS=$(BASEPROGS)/yosys/yosys
ARACHNEPNR=$(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEPACK=$(BASEPROGS)/icestorm/icepack/icepack
IVERILOG=iverilog
VVP=vvp

all: bitstream tests

tests: $(patsubst tests/%.v,tests/obj/%.vvp,$(shell ls tests/test-*.v))

bitstream: obj/top.bin

clean:
	-rm *.vcd
	-rm -rf obj/
	-rm -rf tests/obj/

.PHONY: all clean tests bitstream

#
# Tests
#

tests/obj/test-display-driver-simple.vvp: tests/test-display-driver-simple.v display-driver.v tests/helpers.v
tests/obj/test-display-memory-simple.vvp: tests/test-display-memory-simple.v display-memory.v tests/helpers.v
tests/obj/test-top.vvp: tests/test-top.v top.v display-memory.v display-driver.v tests/helpers.v

tests/obj/test-%.vvp:
	-mkdir -p tests/obj
	$(IVERILOG) -o $@ $^
	$(VVP) $@ -lxt2

#
# Bistream/Synth/etc.
#

obj/top.blif: top.v display-memory.v display-driver.v

# synth, pnr, bitmap
obj/%.blif:
	-mkdir -p $$(dirname $@)
	$(YOSYS) -p 'synth_ice40 -top top -blif $@' $^

obj/%.asc: obj/%.blif %.pcf
	-mkdir -p $$(dirname $@)
	$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^))

obj/%.bin: obj/%.asc
	-mkdir -p $$(dirname $@)
	$(ICEPACK) $^ $@

