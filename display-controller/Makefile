
# output
Q = $(if $(filter $(V),2),,@)
QSH = $(if $(V),,> /dev/null 2>&1)

BASEPROGS = /home/nathan/fpga-ice40
YOSYS = $(BASEPROGS)/yosys/yosys
ARACHNEPNR = $(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEPACK = $(BASEPROGS)/icestorm/icepack/icepack
IVERILOG = iverilog
VVP = vvp


all: bitstream tests

BROKEN =
TESTS = $(patsubst tests/%.v,%,$(shell ls tests/test-*.v))
RUNTESTS = $(filter-out $(BROKEN),$(patsubst tests/%.v,%,$(TESTS)))

tests: $(RUNTESTS)

$(foreach t,$(TESTS),$(eval $t: obj/tests/$t_run))

bitstream: obj/top.bin obj/top.asc

clean:
	@echo "[CLEAN] cleaning..."
	$(Q)-rm -rf *.vcd obj/

.PHONY: all clean tests bitstream $(TESTS)

display-memory.v: obj/initial-image-memory.hex
obj/initial-image-memory.hex: scripts/image-table.py
	@echo "[MEM  ] generating image table"
	$(Q)-mkdir -p $(dir $@)
	$(Q)./scripts/image-table.py > $@

display-color-encoder.v: obj/gamma-lookup-table.hex
obj/gamma-lookup-table.hex: scripts/gamma-correction-tables.py
	@echo "[MEM  ] generating gamma correction table"
	$(Q)-mkdir -p $(dir $@)
	$(Q)./scripts/gamma-correction-tables.py > $@
#
# Tests
#

obj/tests/test-display-driver-simple.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-memory-simple.vvp: display-memory.v
obj/tests/test-display-color-encoder-simple.vvp: display-color-encoder.v
obj/tests/test-spi-slave-simple.vvp: spi-slave.v
obj/tests/test-top.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-slave.v

obj/tests/%.vvp: tests/%.v tests/helpers.v
	$(Q)-mkdir -p $(dir $@)
	@echo "[SIMUL] $(patsubst obj/tests/%.vvp,%,$@)"
	$(Q)$(IVERILOG) -D SIMULATION -g2012 -o $@ $(filter-out tests/helpers.v,$^) $(QSH)

obj/tests/%_run: obj/tests/%.vvp
	@echo "[TEST ] $(patsubst obj/tests/%_run,%,$@)...";
	$(Q)-mkdir -p $(dir $@)
	$(Q)if ! $(VVP) -n $^ -lxt2 $(QSH); then \
			echo "        $(patsubst obj/tests/%_run,%,$@)... Failed"; \
		else \
			echo "        $(patsubst obj/tests/%_run,%,$@)... Passed"; \
		fi

#
# Bistream/Synth/etc.
#

obj/top.blif: display-memory.v display-driver.v display-color-encoder.v spi-slave.v

# synth, pnr, bitmap
obj/%.blif: %.v
	$(Q)-mkdir -p $(dir $@)
	@echo "[SYNTH] $@"
	$(Q)$(YOSYS) -p "$(foreach f,$(filter %.v,$^),read_verilog -DSYNTHESIS $f; ) synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@" $(QSH)

obj/%.asc: obj/%.blif %.pcf
	$(Q)-mkdir -p $(dir $@)
	@echo "[P-N-R] $@"
	$(Q)$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^))

obj/%.bin: obj/%.asc
	$(Q)-mkdir -p $(dir $@)
	@echo "[BMAP ] $@"
	$(Q)$(ICEPACK) $^ $@ $(QSH)

