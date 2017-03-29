
# output
Q = $(if $(filter $(V),2),,@)
QSH = $(if $(V),,> /dev/null 2>&1)

# cmd runner
cmd-pf-call = @ \
	mkdir -p $(dir $@); \
	if ! $(1) > $@.log 2>&1; then \
		cat $@.log $(QSH); \
		printf " %-6s  `tput setaf 1`%4s`tput sgr0`  %s\n" "$(2)" "fail" "$(3)"; \
	else \
		cat $@.log $(QSH); \
		printf " %-6s  `tput setaf 2`%4s`tput sgr0`  %s\n" "$(2)" "pass" "$(3)"; \
	fi; \
	rm $@.log

cmd-call = @ \
	mkdir -p $(dir $@); \
	printf " %-6s  %4s  %s\n" "$(2)" "" "$(3)"; \
	if ! $(1) > $@.log 2>&1; then \
		cat $@.log $(QSH); \
		printf " %-6s  `tput setaf 1`%4s`tput sgr0`  %s\n" "$(2)" "fail" "$(3)"; \
	fi; \
	rm $@.log

cmd-null = @ \
	mkdir -p $(dir $@); \
	printf " %-6s  %4s  %s\n" "$(1)" "" "$(2)"

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
	$(call cmd-null,MEM,generating gamma correction table)
	@./scripts/gamma-correction-tables.py > $@

#
# Tests
#

obj/tests/test-display-driver-simple.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-driver-timing.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-memory-simple.vvp: display-memory.v
obj/tests/test-display-color-encoder-simple.vvp: display-color-encoder.v
obj/tests/test-spi-slave-simple.vvp: spi-slave.v
obj/tests/test-spi-controller.vvp: spi-controller.v spi-slave.v
obj/tests/test-top.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v
obj/tests/test-top-load-spi.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v

obj/tests/%.vvp: tests/%.v tests/helpers.v
	$(call cmd-call,$(IVERILOG) -D SIMULATION -g2012 -o $@ $(filter-out tests/helpers.v,$^),SIM,$(patsubst obj/tests/%.vvp,%,$@))

obj/tests/%_run: obj/tests/%.vvp
	$(call cmd-pf-call,$(VVP) -n $^ -lxt2,TEST,$(patsubst obj/tests/%_run,%,$@))

#
# Bistream/Synth/etc.
#

obj/top.blif: display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v

# synth, pnr, bitmap
obj/%.blif: %.v
	$(call cmd-call,$(YOSYS) -p "$(foreach f,$(filter %.v,$^),read_verilog -defer -DSYNTHESIS $f; ) synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@",SYNTH,$@)

obj/%.asc: obj/%.blif %.pcf
	$(call cmd-call,$(ARACHNEPNR) -d 1k -P tq144 -o $@ -p $(firstword $(filter %.pcf,$^)) $(firstword $(filter %.blif,$^)),P-N-R,$@)
	$(call cmd-pf-call,$(ICETIME) -C $(ICEBOX)/chipdb-1k.txt -d hx1k -P tq144 -p $(firstword $(filter %.pcf,$^)) -c 12 $@,TIMING,$@)

obj/%.bin: obj/%.asc
	$(call cmd-call,$(ICEPACK) $^ $@,BITMAP,$@)

