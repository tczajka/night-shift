ASM     := sjasmplus
FUSE    := fuse-gtk
# Extra emulator options; override with e.g. make run FUSE_FLAGS="-g 4x".
FUSE_FLAGS := -g 4x
BUILD   := build
TAP     := $(BUILD)/nightshift.tap
SOURCES := $(wildcard src/*.asm)
IMAGES  := images/load.scr

# Stricter parsing, warnings as errors (see sjasmplus --help=syntax), and all
# optional warnings.
ASMFLAGS := --syntax=abfw -Wall

.PHONY: all run clean

all: $(TAP)

$(TAP): $(SOURCES) $(IMAGES) | $(BUILD)
	$(ASM) $(ASMFLAGS) --nologo --msg=war --outprefix=$(BUILD)/ \
		--sym=$(BUILD)/nightshift.sym --lst=$(BUILD)/nightshift.lst \
		src/main.asm

$(BUILD):
	mkdir -p $@

run: $(TAP)
	$(FUSE) --machine 48 $(FUSE_FLAGS) $(TAP)

clean:
	rm -rf $(BUILD)
