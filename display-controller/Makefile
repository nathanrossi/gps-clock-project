
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
# source dir and VPATH
S ?= $(shell realpath .)
VPATH = $(S)

# common targets
all: bitstream tests

# bitstream and dependencies
bit: bitstream
bitstream: $(O)/top.bin $(O)/top.asc $(O)/top.asc.timing.log
$(O)/top.blif: top.v \
		display_driver.v display_memory.v \
		data_loader.v \
		spi_controller.v spi_slave.v \
		uart/uart_rx.v \
		$(O)/top_pll_config.v $(O)/gamma_lookup_table_10.hex

# dependencies
$(O)/tests/tests/display_color_encoder_10b.vvp: display_color_encoder.v $(O)/gamma_lookup_table_10.hex
$(O)/tests/tests/display_color_encoder_simple.vvp: display_color_encoder.v $(O)/gamma_lookup_table_10.hex
$(O)/tests/tests/display_driver_10b.vvp: display_driver.v
$(O)/tests/tests/pulse_generator_simple.vvp: display_driver_pulse_generator.v
$(O)/tests/tests/display_driver_pw_timing.vvp: display_driver_pulsewidth.v display_driver_row_loader.v display_driver_rgb_pipe.v display_driver_pulse_generator.v
$(O)/tests/tests/rgb_pipe_simple.vvp: display_driver_rgb_pipe.v
$(O)/tests/tests/row_loader_simple.vvp: display_driver_row_loader.v
$(O)/tests/tests/display_driver_simple.vvp: display_driver.v
$(O)/tests/tests/display_driver_timing.vvp: display_driver.v
$(O)/tests/tests/display_memory_simple.vvp: display_memory.v
$(O)/tests/tests/spi_slave_simple.vvp: spi_slave.v
$(O)/tests/tests/spi_controller_simple.vvp: spi_controller.v spi_slave.v
$(O)/tests/tests/data_loader_simple.vvp: data_loader.v
$(O)/tests/tests/top_load_spi.vvp: top.v display_driver.v display_memory.v spi_controller.v spi_slave.v $(O)/gamma_lookup_table_10.hex
$(O)/tests/tests/top_run.vvp: top.v display_driver.v display_memory.v spi_controller.v spi_slave.v $(O)/gamma_lookup_table_10.hex

$(O)/tests/uart/tests/uart_rx_pattern.vvp: uart/uart_rx.v
$(O)/tests/uart/tests/uart_tx_pattern.vvp: uart/uart_tx.v
$(O)/tests/uart/tests/uart_loopback.vvp: uart/uart_rx.v uart/uart_tx.v

# clean
clean:
	$(call echo-info,CLEAN,cleaning...)
	-@rm -rf $(O)/

.PHONY: all clean tests bit bitstream $(TESTS)

# Gamma generation
$(O)/gamma_lookup_table_%.hex: scripts/gamma-correction-tables.py
	$(call safe-dir)
	$(call echo-info,GLUT,generating gamma correction table for $* bits)
	$(Q)$(abspath $(firstword $^)) $* > $@

# Tests
TESTS_BROKEN =
TESTS_SKIP = tests/top_run tests/top_load_spi
TESTS =
RUNTESTS = $(filter-out $(TESTS_BROKEN) $(TESTS_SKIP),$(TESTS))

setup-tests = \
	$(foreach test,$(patsubst $(S)/%.v,%,$(wildcard $(S)/$(1)/*.v)), \
		$(eval TESTS += $(test)) \
		$(eval $(O)/tests/$(test).vvp: $(test).v))

$(call setup-tests,tests)
$(call setup-tests,uart/tests)

tests: $(RUNTESTS)
$(foreach test,$(TESTS),$(eval $(test): $(O)/tests/$(test).run.log))

# iverilog
$(O)/tests/%.vvp: TEST_NAME = $*
$(O)/tests/%.vvp:
	$(call safe-dir)
	$(call echo-info,SIMU,$(TEST_NAME))
	$(Q)cd $(O) && $(IVERILOG) \
		-o $(abspath $@) \
		-DSIMULATION \
		-DVCD_FILE=$(abspath $(patsubst %.vvp,%.vcd,$@)) \
		-g2012 -I$(abspath $(S)) -I$(abspath $(O)) \
		$(abspath $(filter %.v,$^))

# iverilog/vvp
$(O)/tests/%.run.log: TEST_NAME = $*
$(O)/tests/%.run.log: $(O)/tests/%.vvp
	$(call safe-dir)
	$(Q)cd $(O) && $(VVP) -n $(abspath $^) -lxt2 > $(abspath $@) 2>&1 $(call echo-pf-check,TEST,$(TEST_NAME))
	$(call echo-report-test-assert,$@,$@) $(QSH)

# frequencies for the top level design (in MHz)
SOURCE_FREQ = 12
TARGET_FREQ = 48
TARGET_DEVICE = 1k
TARGET_DEVICE_VARIANT = hx
TARGET_PACKAGE = tq144

# pll source generation
$(O)/%_pll_config.v:
	$(call safe-dir)
	$(call echo-info,PLL,$*)
	$(Q)$(ICEPLL) -i $(SOURCE_FREQ) -o $(TARGET_FREQ) -m -f $@ > $@.log
	$(call echo-report,PLL Configuration for $@,$@.log) $(QSH)

# synth, pnr, bitmap
$(O)/%.blif: %.v
	$(call safe-dir)
	$(call echo-info,SYNTH,$*)
	$(Q)cd $(O) && $(YOSYS) \
		-p "read_verilog -defer -I$(abspath $(O)) -DSYNTHESIS $(abspath $(filter %.v,$^)); \
			synth_ice40 -top $* -blif $(abspath $@)" \
			> $@.synthesis.log 2>&1

$(O)/%.asc: $(O)/%.blif %.pcf
	$(call safe-dir)
	$(call echo-info,P-N-R,$*)
	$(Q)$(ARACHNEPNR) \
		-d $(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-o $@ \
		-p $(abspath $(firstword $(filter %.pcf,$^))) \
		$(abspath $(firstword $(filter %.blif,$^))) \
		> $@.log 2>&1
	$(call echo-report,Place and Route report for $*,$@.log) $(QSH)

$(O)/%.asc.timing.log: $(O)/%.asc $(S)/%.pcf
	$(call safe-dir)
	$(call echo-info,TIMING,$*)
	$(Q)$(ICETIME) \
		-C $(ICEBOX)/chipdb-$(TARGET_DEVICE).txt \
		-d $(TARGET_DEVICE_VARIANT)$(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-p $(abspath $(firstword $(filter %.pcf,$^))) \
		-c $(TARGET_FREQ) $(abspath $(firstword $(filter %.asc,$^))) \
			> $@ 2>&1 $(call echo-pf-check,TIMING,$*)
	$(call echo-report,Timing Report for $*,$@) $(QSH)

$(O)/%.bin: $(O)/%.asc
	$(call safe-dir)
	$(call echo-info,BITMAP,$*)
	$(Q)$(ICEPACK) $(abspath $(firstword $^)) $(abspath $@) $(QSH)

