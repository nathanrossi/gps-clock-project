
# output
Q = $(if $(filter $(V),2),,@)
QSH = $(if $(V),,> /dev/null 2>&1)

tput = $(shell tput $(1) 2> /dev/null)

has-command = $(if $(shell command -v $(1) 2> /dev/null),$(shell command -v $(1) 2> /dev/null),$(2))
has-directory = $(if $(shell test -d $(1) && echo $(1)),$(1),$(2))

safe-dir = @mkdir -p $(dir $@)
echo-info = @printf " %-6s  %4s  %s\n" "$(1)" "" "$(2)"; \

echo-pass = printf " %-6s  $(call tput,setaf 2)%4s$(call tput,sgr0)  %s\n" "$(1)" "pass" "$(2)"
echo-fail = printf " %-6s  $(call tput,setaf 1)%4s$(call tput,sgr0)  %s\n" "$(1)" "fail" "$(2)"
echo-pf-check = ; STATUS=$$?; \
		if [ "$$STATUS" = "0" ]; then \
			$(call echo-pass,$(1),$(2)); \
		else \
			$(call echo-fail,$(1),$(2)); \
		fi
echo-report = @sh -c "echo '-------------------- $(1) --------------------'; cat $(2); echo '-------------------- $(1) --------------------'"
echo-report-test-assert = @sh -c "echo '-------------------- $(1) --------------------'; cat $(2) $(if $(filter $(V),2),,| egrep assertion\|info); echo '-------------------- $(1) --------------------'"

# define variables for commands
# if not found, use BASEPROGS
BASEPROGS = /home/nathan/fpga-ice40
IVERILOG ?= $(call has-command,iverilog)
VVP ?= $(call has-command,vvp)
YOSYS ?= $(call has-command,yosys,$(BASEPROGS)/yosys/yosys)
ARACHNEPNR ?= $(call has-command,arachne-pnr,$(BASEPROGS)/arachne-pnr/bin/arachne-pnr)
ICEPACK ?= $(call has-command,icepack,$(BASEPROGS)/icestorm/icepack/icepack)
ICETIME ?= $(call has-command,icetime,$(BASEPROGS)/icestorm/icetime/icetime)
ICEPLL ?= $(call has-command,icepll,$(BASEPROGS)/icestorm/icepll/icepll)
ICEBOX ?= $(call has-directory,/usr/share/icebox,$(BASEPROGS)/icestorm/icebox)

# output dir
O ?= $(shell realpath obj)
S ?= $(shell realpath .)

all: bitstream tests

TESTS_BROKEN =
TESTS_SKIP = test-top test-top-load-spi
TESTS = $(patsubst $(S)/tests/%.v,%,$(shell ls $(S)/tests/test-*.v))
RUNTESTS = $(filter-out $(TESTS_BROKEN) $(TESTS_SKIP),$(patsubst tests/%.v,%,$(TESTS)))

tests: $(RUNTESTS)

$(foreach t,$(TESTS),$(eval $t: $(O)/tests/$t.run.log))

bit: bitstream
bitstream: $(O)/top.bin $(O)/top.asc $(O)/top.asc.timing.log

clean:
	$(call echo-info,CLEAN,cleaning...)
	-@rm -rf $(O)/


.PHONY: all clean tests bit bitstream $(TESTS)

$(S)/display-color-encoder.v: gamma-lookup-tables
$(S)/display-driver.v: $(S)/display-color-encoder.v
$(S)/display-driver-pulsewidth.v: $(S)/display-driver-row-loader.v $(S)/display-driver-rgb-pipe.v $(S)/display-driver-pulse-generator.v
$(S)/top.v: $(S)/display-driver.v $(S)/display-memory.v $(S)/spi-controller.v

GAMMA_TABLES = 8 9 10 11 12
gamma-lookup-tables: $(foreach t,$(GAMMA_TABLES),$(O)/gamma-lookup-table-$t.hex)

$(O)/gamma-lookup-table-%.hex: BITS = $(patsubst $(O)/gamma-lookup-table-%.hex,%,$@)
$(O)/gamma-lookup-table-%.hex: $(S)/scripts/gamma-correction-tables.py
	$(call safe-dir)
	$(call echo-info,GLUT,generating gamma correction table for $(BITS) bits)
	$(Q)$(S)/scripts/gamma-correction-tables.py $(BITS) > $@

#
# Tests
#

$(O)/tests/test-display-driver-simple.vvp: $(S)/display-driver.v $(S)/display-color-encoder.v
$(O)/tests/test-display-driver-10b.vvp: $(S)/display-driver.v $(S)/display-color-encoder.v
$(O)/tests/test-display-driver-timing.vvp: $(S)/display-driver.v $(S)/display-color-encoder.v
$(O)/tests/test-display-driver-rgb-pipe.vvp: $(S)/display-driver-rgb-pipe.v
$(O)/tests/test-display-driver-pw-timing.vvp: $(S)/display-driver-pulsewidth.v $(S)/display-driver-row-loader.v $(S)/display-driver-rgb-pipe.v $(S)/display-driver-pulse-generator.v
$(O)/tests/test-display-driver-pulsewidth.vvp: $(S)/display-driver-pulsewidth.v $(S)/display-driver-row-loader.v $(S)/display-driver-rgb-pipe.v $(S)/display-driver-pulse-generator.v
$(O)/tests/test-display-driver-pulse-generator.vvp: $(S)/display-driver-pulse-generator.v
$(O)/tests/test-display-driver-row-loader.vvp: $(S)/display-driver-row-loader.v
$(O)/tests/test-display-memory-simple.vvp: $(S)/display-memory.v
$(O)/tests/test-display-color-encoder-simple.vvp: $(S)/display-color-encoder.v
$(O)/tests/test-display-color-encoder-10b.vvp: $(S)/display-color-encoder.v
$(O)/tests/test-spi-slave-simple.vvp: $(S)/spi-slave.v
$(O)/tests/test-spi-controller.vvp: $(S)/spi-controller.v $(S)/spi-slave.v
$(O)/tests/test-spi-controller-segments.vvp: $(S)/spi-controller.v $(S)/spi-slave.v
$(O)/tests/test-top.vvp: $(S)/top.v $(S)/display-memory.v $(S)/display-driver.v $(S)/display-color-encoder.v $(S)/spi-controller.v $(S)/spi-slave.v
$(O)/tests/test-top-load-spi.vvp: $(S)/top.v $(S)/display-memory.v $(S)/display-driver.v $(S)/display-color-encoder.v $(S)/spi-controller.v $(S)/spi-slave.v

$(O)/tests/%.vvp: TEST_NAME = $(patsubst $(O)/tests/%.vvp,%,$@)
$(O)/tests/%.vvp: $(S)/tests/%.v $(S)/tests/helpers.v
	$(call safe-dir)
	$(call echo-info,SIMU,$(TEST_NAME))
#	$(Q)$(IVERILOG) -E -D SIMULATION -g2012 -o $@.pp $(filter-out $(S)/tests/helpers.v,$^)
	$(Q)cd $(O) && $(IVERILOG) \
		-DSIMULATION \
		-DVCD_FILE=$(patsubst %.vvp,%.vcd,$@) \
		-g2012 -I$(S) -I$(O) -y$(O) -o $@ \
		$(filter-out $(S)/tests/helpers.v,$^)

$(O)/tests/%.run.log: TEST_NAME = $(patsubst $(O)/tests/%.run.log,%,$@)
$(O)/tests/%.run.log: $(O)/tests/%.vvp
	$(call safe-dir)
	$(Q)cd $(O) && $(VVP) -n $^ -lxt2 > $@ 2>&1 $(call echo-pf-check,TEST,$(TEST_NAME))
	$(call echo-report-test-assert,$@,$@) $(QSH)

#
# Bistream/Synth/etc.
#

# frequencies for the top level design (in MHz)
SOURCE_FREQ = 12
TARGET_FREQ = 48
TARGET_DEVICE = 1k
TARGET_DEVICE_VARIANT = hx
TARGET_PACKAGE = tq144

$(O)/top-pll-config.v:
	$(call safe-dir)
	$(call echo-info,PLL,$@)
	$(Q)$(ICEPLL) -i $(SOURCE_FREQ) -o $(TARGET_FREQ) -m -f $@ > $@.log
	$(call echo-report,PLL Configuration for $@,$@.log) $(QSH)

$(O)/top.blif: $(S)/display-memory.v $(S)/display-driver.v $(S)/display-color-encoder.v $(S)/spi-controller.v $(S)/spi-slave.v $(O)/top-pll-config.v

# synth, pnr, bitmap
$(O)/%.blif: $(S)/%.v
	$(call safe-dir)
	$(call echo-info,SYNTH,$@)
	$(Q)cd $(O) && $(YOSYS) \
		-p "$(foreach f,$(filter %.v,$^),read_verilog -defer -I$(O) -DSYNTHESIS $f; ) synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@" \
			> $@.synthesis.log 2>&1

$(O)/%.asc: $(O)/%.blif $(S)/%.pcf
	$(call safe-dir)
	$(call echo-info,P-N-R,$@)
	$(Q)$(ARACHNEPNR) \
		-d $(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-o $@ \
		-p $(firstword $(filter %.pcf,$^)) \
		$(firstword $(filter %.blif,$^)) \
		> $@.log 2>&1
	$(call echo-report,Place and Route report for $@,$@.log) $(QSH)

$(O)/%.asc.timing.log: $(O)/%.asc $(S)/%.pcf
	$(call safe-dir)
	$(call echo-info,TIMING,$@)
	$(Q)$(ICETIME) \
		-C $(ICEBOX)/chipdb-$(TARGET_DEVICE).txt \
		-d $(TARGET_DEVICE_VARIANT)$(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-p $(firstword $(filter %.pcf,$^)) \
		-c $(TARGET_FREQ) $(firstword $(filter %.asc,$^)) \
			> $@ 2>&1 $(call echo-pf-check,TIMING,$@)
	$(call echo-report,Timing Report for $@,$@) $(QSH)

$(O)/%.bin: $(O)/%.asc
	$(call safe-dir)
	$(call echo-info,BITMAP,$@)
	$(Q)$(ICEPACK) $^ $@ $(QSH)

