
# output
Q = $(if $(filter $(V),2),,@)
QSH = $(if $(V),,> /dev/null 2>&1)

safe-dir = @mkdir -p $(dir $@)
echo-info = @printf " %-6s  %4s  %s\n" "$(1)" "" "$(2)"; \

echo-pass = printf " %-6s  `tput setaf 2`%4s`tput sgr0`  %s\n" "$(1)" "pass" "$(2)"
echo-fail = printf " %-6s  `tput setaf 1`%4s`tput sgr0`  %s\n" "$(1)" "fail" "$(2)"
echo-pf-check = ; STATUS=$$?; \
		if [ "$$STATUS" = "0" ]; then \
			$(call echo-pass,$(1),$(2)); \
		else \
			$(call echo-fail,$(1),$(2)); \
		fi

BASEPROGS = /home/nathan/fpga-ice40
YOSYS = $(BASEPROGS)/yosys/yosys
ARACHNEPNR = $(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEBOX = $(BASEPROGS)/icestorm/icebox
ICEPACK = $(BASEPROGS)/icestorm/icepack/icepack
ICETIME = $(BASEPROGS)/icestorm/icetime/icetime
IVERILOG = iverilog
VVP = vvp

all: bitstream tests

BROKEN =
TESTS = $(patsubst tests/%.v,%,$(shell ls tests/test-*.v))
RUNTESTS = $(filter-out $(BROKEN),$(patsubst tests/%.v,%,$(TESTS)))

tests: $(RUNTESTS)

$(foreach t,$(TESTS),$(eval $t: obj/tests/$t_run))

bit: bitstream
bitstream: obj/top.bin obj/top.asc

clean:
	$(call cmd-call,rm -rf *.vcd obj/,CLEAN,cleaning...)

.PHONY: all clean tests bit bitstream $(TESTS)

display-color-encoder.v: obj/gamma-lookup-table.hex
display-driver.v: display-color-encoder.v
top.v: display-driver.v display-memory.v spi-controller.v

obj/gamma-lookup-table.hex: scripts/gamma-correction-tables.py
	$(call safe-dir)
	$(call echo-info,MEM,generating gamma correction table)
	$(Q)./scripts/gamma-correction-tables.py > $@

#
# Tests
#

obj/tests/test-display-driver-simple.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-driver-timing.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-memory-simple.vvp: display-memory.v
obj/tests/test-display-color-encoder-simple.vvp: display-color-encoder.v
obj/tests/test-spi-slave-simple.vvp: spi-slave.v
obj/tests/test-spi-controller.vvp: spi-controller.v spi-slave.v
obj/tests/test-spi-controller-segments.vvp: spi-controller.v spi-slave.v
obj/tests/test-top.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v
obj/tests/test-top-load-spi.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v

obj/tests/%.vvp: tests/%.v tests/helpers.v
	$(call safe-dir)
	$(call echo-info,SIM,$(patsubst obj/tests/%.vvp,%,$@))
	$(Q)$(IVERILOG) -D SIMULATION -g2012 -o $@ $(filter-out tests/helpers.v,$^)

obj/tests/%_run: INFO_NAME = TEST
obj/tests/%_run: obj/tests/%.vvp
	$(call safe-dir)
	$(call echo-info,$(INFO_NAME),$(patsubst obj/tests/%_run,%,$@))
	$(Q)$(VVP) -n $^ -lxt2 $(QSH) $(call echo-pf-check,$(INFO_NAME),$(patsubst obj/tests/%_run,%,$@))

#
# Bistream/Synth/etc.
#

obj/top.blif: display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v

# synth, pnr, bitmap
obj/%.blif: %.v
	$(call safe-dir)
	$(call echo-info,SYNTH,$@)
	$(Q)$(YOSYS) -p "$(foreach f,$(filter %.v,$^),read_verilog -defer -DSYNTHESIS $f; ) synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@" $(QSH)

obj/%.asc: obj/%.blif %.pcf
	$(call safe-dir)
	$(call echo-info,P-N-R,$@)
	$(Q)$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^)) $(QSH)
	$(call echo-info,TIMING,$@)
	$(Q)$(ICETIME) -C $(ICEBOX)/chipdb-1k.txt -d hx1k -P tq144 -p $(firstword $(filter %.pcf,$^)) -c 12 $@ $(QSH)

obj/%.bin: obj/%.asc
	$(call safe-dir)
	$(call echo-info,BITMAP,$@)
	$(Q)$(ICEPACK) $^ $@ $(QSH)

