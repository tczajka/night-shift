ASM     := sjasmplus
FUSE    := fuse-gtk
BUILD   := build
TAP     := $(BUILD)/nightshift.tap
SOURCES := $(wildcard src/*.asm)

# Stricter parsing (see sjasmplus --help=syntax) and all optional warnings.
# Not using the 'w' (warnings as errors) syntax option: the whole-RAM
# SAVETAP always warns, and that warning cannot be suppressed.
ASMFLAGS := --syntax=abf -Wall

.PHONY: all run clean

all: $(TAP)

$(TAP): $(SOURCES) | $(BUILD)
	$(ASM) $(ASMFLAGS) --nologo --msg=war --outprefix=$(BUILD)/ \
		--sym=$(BUILD)/nightshift.sym --lst=$(BUILD)/nightshift.lst \
		src/main.asm

$(BUILD):
	mkdir -p $@

run: $(TAP)
	$(FUSE) --machine 48 $(TAP)

clean:
	rm -rf $(BUILD)
