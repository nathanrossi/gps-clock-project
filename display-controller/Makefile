
BASEPROGS=/home/nathan/fpga-ice40
YOSYS=$(BASEPROGS)/yosys/yosys
ARACHNEPNR=$(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEPACK=$(BASEPROGS)/icestorm/icepack/icepack
IVERILOG=iverilog
VVP=vvp

all: simple.bin

tests: $(patsubst tests/%.v,tests/obj/%.vvp,$(shell ls tests/test-*.v))

clean:
	-rm *.bin *.asc *.blif *.vcd
	-rm -rf tests/obj/

.PHONY: all clean test

tests/obj/test-display-driver-simple.vvp: tests/test-display-driver-simple.v display-driver.v tests/helpers.v

tests/obj/test-%.vvp:
	-mkdir -p tests/obj
	$(IVERILOG) -o $@ $^
	$(VVP) $@ -lxt2

# synth, pnr, bitmap
%.blif:
	$(YOSYS) -p 'synth_ice40 -top top -blif $@' $^

%.asc: %.blif %.pcf
	$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^))

%.bin: %.asc
	$(ICEPACK) $^ $@

