
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
echo-report = @sh -c "echo '-------------------- $(1) --------------------'; cat $(2); echo '-------------------- $(1) --------------------'"
echo-report-test-assert = @sh -c "echo '-------------------- $(1) --------------------'; cat $(2) | grep assertion; echo '-------------------- $(1) --------------------'"

BASEPROGS = /home/nathan/fpga-ice40
YOSYS = $(BASEPROGS)/yosys/yosys
ARACHNEPNR = $(BASEPROGS)/arachne-pnr/bin/arachne-pnr
ICEBOX = $(BASEPROGS)/icestorm/icebox
ICEPACK = $(BASEPROGS)/icestorm/icepack/icepack
ICETIME = $(BASEPROGS)/icestorm/icetime/icetime
ICEPLL = $(BASEPROGS)/icestorm/icepll/icepll
IVERILOG = iverilog
VVP = vvp

all: bitstream tests

TESTS_BROKEN =
TESTS_SKIP = test-top test-top-load-spi
TESTS = $(patsubst tests/%.v,%,$(shell ls tests/test-*.v))
RUNTESTS = $(filter-out $(TESTS_BROKEN) $(TESTS_SKIP),$(patsubst tests/%.v,%,$(TESTS)))

tests: $(RUNTESTS)

$(foreach t,$(TESTS),$(eval $t: obj/tests/$t.run.log))

bit: bitstream
bitstream: obj/top.bin obj/top.asc obj/top.asc.timing.log

clean:
	$(call echo-info,CLEAN,cleaning...)
	-@rm -rf obj/


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
obj/tests/test-display-driver-10b.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-driver-timing.vvp: display-driver.v display-color-encoder.v
obj/tests/test-display-memory-simple.vvp: display-memory.v
obj/tests/test-display-color-encoder-simple.vvp: display-color-encoder.v
obj/tests/test-display-color-encoder-10b.vvp: display-color-encoder.v
obj/tests/test-spi-slave-simple.vvp: spi-slave.v
obj/tests/test-spi-controller.vvp: spi-controller.v spi-slave.v
obj/tests/test-spi-controller-segments.vvp: spi-controller.v spi-slave.v
obj/tests/test-top.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v
obj/tests/test-top-load-spi.vvp: top.v display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v

obj/tests/%.vvp: TEST_NAME = $(patsubst obj/tests/%.vvp,%,$@)
obj/tests/%.vvp: tests/%.v tests/helpers.v
	$(call safe-dir)
	$(call echo-info,SIM,$(TEST_NAME))
#	$(Q)$(IVERILOG) -E -D SIMULATION -g2012 -o $@.pp $(filter-out tests/helpers.v,$^)
	$(Q)$(IVERILOG) -D SIMULATION -g2012 -o $@ $(filter-out tests/helpers.v,$^)

obj/tests/%.run.log: TEST_NAME = $(patsubst obj/tests/%.run.log,%,$@)
obj/tests/%.run.log: obj/tests/%.vvp
	$(call safe-dir)
	$(call echo-info,TEST,$(TEST_NAME))
	$(Q)$(VVP) -n $^ -lxt2  2>&1 > $@ $(call echo-pf-check,TEST,$(TEST_NAME))
	$(call echo-report-test-assert,$@,$@) $(QSH)

#
# Bistream/Synth/etc.
#

# frequencies for the top level design (in MHz)
SOURCE_FREQ = 12
TARGET_FREQ = 24
TARGET_DEVICE = 1k
TARGET_DEVICE_VARIANT = hx
TARGET_PACKAGE = tq144

obj/top-pll-config.v:
	$(call safe-dir)
	$(call echo-info,PLL,$@)
	$(Q)$(ICEPLL) -i $(SOURCE_FREQ) -o $(TARGET_FREQ) -m -f $@ > $@.log
	$(call echo-report,PLL Configuration for $@,$@.log) $(QSH)

obj/top.blif: display-memory.v display-driver.v display-color-encoder.v spi-controller.v spi-slave.v obj/top-pll-config.v

# synth, pnr, bitmap
obj/%.blif: %.v
	$(call safe-dir)
	$(call echo-info,SYNTH,$@)
	$(Q)$(YOSYS) \
		-p "$(foreach f,$(filter %.v,$^),read_verilog -defer -DSYNTHESIS $f; ) synth_ice40 -top $$(basename $@ .blif | sed s/-/_/) -blif $@" \
			2>&1 > $@.synthesis.log

obj/%.asc: obj/%.blif %.pcf
	$(call safe-dir)
	$(call echo-info,P-N-R,$@)
	$(Q)$(ARACHNEPNR) \
		-d $(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-o $@ \
		-p $(firstword $(filter %.pcf,$^)) \
		$(firstword $(filter %.blif,$^)) $(QSH)

obj/%.asc.timing.log: obj/%.asc %.pcf
	$(call safe-dir)
	$(call echo-info,TIMING,$@)
	$(Q)$(ICETIME) \
		-C $(ICEBOX)/chipdb-$(TARGET_DEVICE).txt \
		-d $(TARGET_DEVICE_VARIANT)$(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-p $(firstword $(filter %.pcf,$^)) \
		-c $(TARGET_FREQ) $(firstword $(filter %.asc,$^)) \
			2>&1 > $@ $(call echo-pf-check,TIMING,$@)
	$(call echo-report,Timing Report for $@,$@) $(QSH)

obj/%.bin: obj/%.asc
	$(call safe-dir)
	$(call echo-info,BITMAP,$@)
	$(Q)$(ICEPACK) $^ $@ $(QSH)

