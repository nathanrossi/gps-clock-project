
MCU = atmega328p
F_CPU = 8000000

ROOT=.
SRCDIR = $(ROOT)
BINDIR = $(ROOT)/bin
OBJDIR = $(BINDIR)/obj

CC = avr-gcc
SIZE = avr-size
OBJCOPY = avr-objcopy
OBJDUMP = avr-objdump
#
# Compiler Options
CFLAGS = -gdwarf-2 -std=gnu99
CFLAGS += -DF_CPU=$(F_CPU)UL -Os
CFLAGS += -funsigned-char -funsigned-bitfields -fpack-struct -fshort-enums
CFLAGS += -Wall -Wstrict-prototypes
AFLAGS = -x assembler-with-cpp

# Linker Options
LDFLAGS = -Wl,-Map=$(BINDIR)/$@.map,--cref
LDFLAGS += -lm

ALL_CFLAGS = -mmcu=$(MCU) -I$(SRCDIR) $(CFLAGS)
ALL_AFLAGS = -mmcu=$(MCU) -I$(SRCDIR) $(AFLAGS)

printelfsize = @if [ -f $(1) ]; then $(SIZE) --mcu=$(MCU) --format=avr $(1); fi
subsrcs = $(patsubst %.s,$(2)/%.o,$(patsubst %.c,$(2)/%.o,$(1)))
createdir = if [ ! -e $$(dirname $(1)) ]; then mkdir -p $$(dirname $(1)); fi

MAIN=test-screen-avr

.PHONY: clean all program $(MAIN)
.PRECIOUS : %.o

all: $(MAIN)
$(MAIN): $(MAIN).elf $(MAIN).hex
$(MAIN).elf: $(OBJDIR)/$(MAIN).o

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	@echo Compiling $< as $@
	@$(call createdir,$@)
	@$(CC) -c $(ALL_CFLAGS) $(abspath $<) -o $@

%.elf:
	@echo Linking $(BINDIR)/$@
	@mkdir -p $(BINDIR)
	@$(CC) $(ALL_CFLAGS) $(abspath $^) --output $(BINDIR)/$@ $(LDFLAGS)
	$(call printelfsize,$(BINDIR)/$@)

# Create final output files (.hex, .eep) from ELF output file.
%.hex: $(BINDIR)/%.elf
	@echo Creating $(BINDIR)/$@ for $^
	@mkdir -p $(BINDIR)
	@$(OBJCOPY) -O ihex -R .eeprom -R .fuse -R .lock $< $(BINDIR)/$@

clean:
	@echo "Cleaning generated files (continue if fail)"
	- rm -rf $(OBJDIR)
	- rm -rf $(BINDIR)/*.hex $(BINDIR)/*.bin $(BINDIR)/*.elf $(BINDIR)/*.lss $(BINDIR)/*.map

program: $(MAIN).hex
	@echo "Programming $^"
	scp $(BINDIR)/$^ 10.0.0.110:~/
	@sleep 1
	ssh 10.0.0.110 avrdude -c arduino -b 57600 -P /dev/ttyUSB0 -p m328p -u -U flash:w:$^

