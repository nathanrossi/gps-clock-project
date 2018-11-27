
# output
Q = $(if $(filter $(V),2),,@)
QSH = $(if $(V),,> /dev/null 2>&1)

tput = $(shell tput $(1) 2> /dev/null)

has-command = $(if $(shell command -v $(1) 2> /dev/null),$(shell command -v $(1) 2> /dev/null),$(2))
has-directory = $(if $(shell test -d $(1) && echo $(1)),$(1),$(2))

safe-dir = @mkdir -p $(dir $@)
echo-info = @printf " %-12s  %4s  %s\n" "$(1)" "" "$(2)"; \

echo-pass = printf " %-12s  $(call tput,setaf 2)%4s$(call tput,sgr0)  %s\n" "$(1)" "pass" "$(2)"
echo-fail = printf " %-12s  $(call tput,setaf 1)%4s$(call tput,sgr0)  %s\n" "$(1)" "fail" "$(2)"
echo-report = @sh -c "echo '-------------------- $(1) --------------------'; cat $(2); echo '-------------------- $(1) --------------------'"
echo-report-test-assert = @sh -c "echo '-------------------- $(1) --------------------'; cat $(2) $(if $(filter $(V),2),,| egrep assertion\|info); echo '-------------------- $(1) --------------------'"

echo-pf-check = ; if [ $$? = 0 ]; then $(call echo-pass,$(1),$(2)); else $(call echo-fail,$(1),$(2)); fi
log-report = > $(1) 2>&1; if [ $$? != 0 ]; then cat $(1); exit $$?; fi

# define variables for commands
IVL_PATH ?= $(abspath $(dir $(realpath $(call has-command,iverilog)))/../lib/ivl)
IVERILOG ?= $(call has-command,iverilog) -B$(IVL_PATH)
VVP ?= $(call has-command,vvp) -M$(IVL_PATH)
YOSYS ?= $(call has-command,yosys)
ARACHNEPNR ?= $(call has-command,arachne-pnr)
NEXTPNR ?= $(call has-command,nextpnr-ice40)
ICEPACK ?= $(call has-command,icepack)
ICETIME ?= $(call has-command,icetime)
ICEPLL ?= $(call has-command,icepll)

# output dir
O ?= $(shell realpath obj)
# source dir and VPATH
S ?= $(shell realpath .)
VPATH = $(S)

# common targets
all: bitstream-icestick bitstream-up5k

# frequencies for the top level design (in MHz)
TARGET_FREQ = 24
DEFAULT_MODULES = *.v uart/*.v

# bitstream and dependencies
bitstream-icestick: $(O)/board_icestick.bin
$(O)/board_icestick.bin: SOURCE_FREQ = 12
$(O)/board_icestick.bin: TARGET_DEVICE = hx1k
$(O)/board_icestick.bin: TARGET_PACKAGE = tq144
$(O)/board_icestick.bin: $(O)/board_icestick.nextpnr.asc
$(O)/board_icestick.blif $(O)/board_icestick.yosys.json: board_icestick.v $(O)/board_icestick_pll_config.v $(DEFAULT_MODULES)

bitstream-up5k: $(O)/board_up5k.bin
$(O)/board_up5k.bin: SOURCE_FREQ = 48
$(O)/board_up5k.bin: TARGET_DEVICE = up5k
$(O)/board_up5k.bin: TARGET_PACKAGE = sg48
$(O)/board_up5k.bin: $(O)/board_up5k.nextpnr.asc
$(O)/board_up5k.blif $(O)/board_up5k.yosys.json: board_up5k.v $(O)/board_up5k_pll_config.v $(DEFAULT_MODULES)

# gamma dep
display_color_encoder.v: $(O)/gamma_lookup_table_10.hex

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

setup-usage = \
	$(foreach module,$(patsubst $(S)/%.v,%,$(wildcard $(S)/$(1)/*.v)), \
		$(eval MODULES += $(module)) \
		$(eval $(O)/usage/$(module).blif: $(module).v))

$(call setup-usage,.)
$(call setup-usage,uart)

usages: $(foreach module,$(MODULES),$(O)/usage/$(module).blif)
	$(Q)for i in $(foreach log,$^,$(log).synthesis.log); do \
		cat $$i | sed '/^[[:digit:]\.]* Printing.*$$/,/^[[:digit:]].*$$/{//!b};d'; \
	done

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

# pll source generation
$(O)/%_pll_config.v:
	$(call safe-dir)
	$(call echo-info,PLL,$*)
	$(Q)$(ICEPLL) -i $(SOURCE_FREQ) -o $(TARGET_FREQ) -m -f $@ \
		$(call log-report,$@.log)

# synth, pnr, bitmap
$(O)/%.blif $(O)/%.yosys.json: FLAGS = -DSYNTHESIS -DTARGET_FREQ=$(TARGET_FREQ)
$(O)/%.blif $(O)/%.yosys.json:
	$(call safe-dir)
	$(call echo-info,SYNTH,$*)
	$(Q)cd $(O); $(YOSYS) \
		-p " \
			read_verilog -defer -I$(abspath $(O)) $(FLAGS) $(abspath $(filter %.v,$^)); \
			synth_ice40 -top $(notdir $*) -json $(abspath $(O)/$*.yosys.json) -blif $(abspath $(O)/$*.blif); \
		" $(call log-report,$@.synthesis.log)
	$(Q)cat $@.synthesis.log | sed '/^[[:digit:]\.]* Printing.*$$/,/^[[:digit:]].*$$/{//!b};d'

$(O)/%.arachne.asc: $(O)/%.blif %.pcf
	$(call safe-dir)
	$(call echo-info,PNR arachne,$*)
	$(Q)$(ARACHNEPNR) \
		-d $(foreach d,384 1k 5k lm4k 8k,$(findstring $(d),$(TARGET_DEVICE))) \
		-P $(TARGET_PACKAGE) \
		-o $@ \
		-p $(abspath $(firstword $(filter %.pcf,$^))) \
		$(abspath $(firstword $(filter %.blif,$^))) \
		$(call log-report,$@.log)
	$(Q)echo ""; echo "=== $* (packed) ==="; echo ""
	$(Q)cat $@.log | sed '/^After packing:$$/,/^$$/{//!b};d'
	$(Q)echo ""; echo "=== $* (placed) ==="; echo ""
	$(Q)cat $@.log | sed '/^After placement:$$/,/^$$/{//!b};d'
	$(Q)echo ""
	$(Q)$(call log-report,$@.timing.log,$(ICETIME) \
		-d $(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-p $(abspath $(firstword $(filter %.pcf,$^))) \
		-c $(TARGET_FREQ) $@) \
		$(call log-report,$@.log) \
		$(call echo-pf-check,TIMING,$*)

$(O)/%.nextpnr.asc: $(O)/%.yosys.json %.pcf
	$(call safe-dir)
	$(call echo-info,PNR nextpnr,$*)
	$(Q)$(NEXTPNR) \
		--$(TARGET_DEVICE) \
		--json $(abspath $(firstword $(filter %.yosys.json,$^))) \
		--pcf $(abspath $(firstword $(filter %.pcf,$^))) \
		--asc $@ \
		$(call log-report,$@.log)
	$(Q)echo ""; echo "=== $* ==="; echo ""
	$(Q)cat $@.log | sed '/^Info: Device utilisation:$$/,/^$$/{//!b};d' | sed 's/^Info://'
	$(Q)echo ""
	$(Q)$(call log-report,$@.timing.log,$(ICETIME) \
		-d $(TARGET_DEVICE) \
		-P $(TARGET_PACKAGE) \
		-p $(abspath $(firstword $(filter %.pcf,$^))) \
		-c $(TARGET_FREQ) $@) \
		$(call echo-pf-check,TIMING,$*)

$(O)/%.bin:
	$(call safe-dir)
	$(call echo-info,BITMAP,$*)
	$(Q)$(ICEPACK) $(abspath $(firstword $^)) $(abspath $@) $(QSH)

