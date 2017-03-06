
# output
Q = @
QSH = > /dev/null 2>&1

BASEPROGS = /home/nathan/fpga-ice40
YOSYS = $(BASEPROGS)/yosys/yosys
ARACHNEPNR = $(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEPACK = $(BASEPROGS)/icestorm/icepack/icepack
IVERILOG = iverilog
VVP = vvp


all: bitstream tests

BROKEN = test-display-driver-simple
TESTS = $(patsubst tests/%.v,%,$(shell ls tests/test-*.v))
RUNTESTS = $(filter-out $(BROKEN),$(patsubst tests/%.v,%,$(TESTS)))

tests: $(RUNTESTS)

$(foreach t,$(TESTS),$(eval $t: obj/tests/$t_run))

bitstream: obj/top.bin obj/top.asc

clean:
	@echo "[CLEAN] cleaning..."
	$(Q)-rm *.vcd
	$(Q)-rm -rf obj/
	$(Q)-rm -rf obj/tests/

.PHONY: all clean tests bitstream $(TESTS)

#
# Tests
#

obj/tests/test-display-driver-simple.vvp: display-driver.v
obj/tests/test-display-driver-mod2-simple.vvp: display-driver-mod2.v
obj/tests/test-display-driver-mod3-simple.vvp: display-driver-mod3.v
obj/tests/test-display-memory-simple.vvp: display-memory.v
obj/tests/test-display-color-encoder-simple.vvp: display-color-encoder.v
obj/tests/test-spi-slave-simple.vvp: spi-slave.v
obj/tests/test-top.vvp: top.v display-memory.v display-driver.v display-driver-mod2.v display-color-encoder.v spi-slave.v

obj/tests/%.vvp: tests/%.v tests/helpers.v
	$(Q)-mkdir -p obj/tests
	@echo "[SIMUL] $(patsubst obj/tests/%.vvp,%,$@)"
	$(Q)$(IVERILOG) -g2012 -o $@ $(filter-out tests/helpers.v,$^) $(QSH)

obj/tests/%_run: obj/tests/%.vvp
	@echo "[TEST ] $(patsubst obj/tests/%_run,%,$@)...";
	$(Q)if ! $(VVP) -n $^ -lxt2 $(QSH); then \
			echo "        $(patsubst obj/tests/%_run,%,$@)... Failed"; \
		else \
			echo "        $(patsubst obj/tests/%_run,%,$@)... Passed"; \
		fi

display-memory.v: initial-image-memory.hex
initial-image-memory.hex: image-table.py
	@echo "[IMGTB] generating image table"
	$(Q)./image-table.py > initial-image-memory.hex

#
# Bistream/Synth/etc.
#

obj/top.blif: display-memory.v display-driver.v display-driver-mod2.v display-color-encoder.v spi-slave.v initial-image-memory.hex

# synth, pnr, bitmap
obj/%.blif: %.v
	$(Q)-mkdir -p $$(dirname $@)
	@echo "[SYNTH] $@"
	$(Q)$(YOSYS) -p "synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@" $(filter %.v,$^) $(QSH)

obj/%.asc: obj/%.blif %.pcf
	$(Q)-mkdir -p $$(dirname $@)
	@echo "[P-N-R] $@"
	$(Q)$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^)) $(QSH)

obj/%.bin: obj/%.asc
	$(Q)-mkdir -p $$(dirname $@)
	@echo "[BMAP ] $@"
	$(Q)$(ICEPACK) $^ $@ $(QSH)

