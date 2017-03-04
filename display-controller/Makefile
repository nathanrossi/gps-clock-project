
BASEPROGS=/home/nathan/fpga-ice40
YOSYS=$(BASEPROGS)/yosys/yosys
ARACHNEPNR=$(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEPACK=$(BASEPROGS)/icestorm/icepack/icepack
IVERILOG=iverilog
VVP=vvp

all: bitstream tests

tests: $(patsubst tests/%.v,obj/tests/%.vvp,$(shell ls tests/test-*.v))

bitstream: obj/top.bin

clean:
	-rm *.vcd
	-rm -rf obj/
	-rm -rf obj/tests/

.PHONY: all clean tests bitstream

#
# Tests
#

obj/tests/test-display-driver-simple.vvp: display-driver.v
obj/tests/test-display-memory-simple.vvp: display-memory.v
obj/tests/test-display-color-encoder-simple.vvp: display-color-encoder.v
obj/tests/test-spi-slave-simple.vvp: spi-slave.v
obj/tests/test-top.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-slave.v

obj/tests/test-%.vvp: tests/test-%.v tests/helpers.v
	-mkdir -p obj/tests
	$(IVERILOG) -o $@ $^
	$(VVP) $@ -lxt2

#
# Bistream/Synth/etc.
#

obj/top.blif: display-memory.v display-driver.v display-color-encoder.v spi-slave.v

# synth, pnr, bitmap
obj/%.blif: %.v
	-mkdir -p $$(dirname $@)
	$(YOSYS) -p "synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@" $^

obj/%.asc: obj/%.blif %.pcf
	-mkdir -p $$(dirname $@)
	$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^))

obj/%.bin: obj/%.asc
	-mkdir -p $$(dirname $@)
	$(ICEPACK) $^ $@

