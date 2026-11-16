ASM     := sjasmplus
# ZEsarUX runs from its own directory, where its ROMs are.
ZESARUX_DIR := $(HOME)/opt/zesarux-13.0/ZEsarUX-13.0
# Extra emulator options; override with e.g. make run ZESARUX_FLAGS="--zoom 2".
ZESARUX_FLAGS := --zoom 5 --realvideo --nowelcomemessage
BUILD   := build
TAP     := $(BUILD)/nightshift.tap
SOURCES := $(wildcard src/*.asm)
IMAGES  := images/load.scr
PYTHON  := python3

# Level data (design/level-format.md), built from the Sokoban text files by
# tools/levels.py. Its report of every level goes to levels.txt.
LEVEL_SOURCES := levels/Microban.sok
LEVELS  := $(BUILD)/levels.bin

# Stricter parsing, warnings as errors, whole-word-only DEFINE substitution
# (see sjasmplus --help=syntax), and all optional warnings.
ASMFLAGS := --syntax=abfsw -Wall

# make PROFILE=1 assembles the profiling aids in src/profile.asm.
ifdef PROFILE
ASMFLAGS += -DPROFILE
endif

# Rebuild when ASMFLAGS change (e.g. switching PROFILE on or off): the
# flags file is rewritten only when its contents would differ.
FLAGS_FILE := $(BUILD)/asmflags

.PHONY: all run clean FORCE

# Don't leave a tape behind when assembly fails.
.DELETE_ON_ERROR:

all: $(TAP)

$(TAP): $(SOURCES) $(IMAGES) $(LEVELS) $(FLAGS_FILE) | $(BUILD)
	$(ASM) $(ASMFLAGS) --nologo --msg=war --outprefix=$(BUILD)/ \
		--sym=$(BUILD)/nightshift.sym --lst=$(BUILD)/nightshift.lst \
		src/main.asm

$(LEVELS): tools/levels.py $(LEVEL_SOURCES) | $(BUILD)
	$(PYTHON) tools/levels.py $@ $(LEVEL_SOURCES) > $(BUILD)/levels.txt

$(FLAGS_FILE): FORCE | $(BUILD)
	@echo '$(ASMFLAGS)' | cmp -s - $@ || echo '$(ASMFLAGS)' > $@

$(BUILD):
	mkdir -p $@

run: $(TAP)
	cd $(ZESARUX_DIR) && ./zesarux --machine 48k $(ZESARUX_FLAGS) $(abspath $(TAP))

clean:
	rm -rf $(BUILD)
