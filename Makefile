ASM     := sjasmplus
FUSE    := fuse-gtk
# Extra emulator options; override with e.g. make run FUSE_FLAGS="-g 4x".
FUSE_FLAGS := -g 4x
BUILD   := build
TAP     := $(BUILD)/nightshift.tap
SOURCES := $(wildcard src/*.asm)
IMAGES  := images/load.scr

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

$(TAP): $(SOURCES) $(IMAGES) $(FLAGS_FILE) | $(BUILD)
	$(ASM) $(ASMFLAGS) --nologo --msg=war --outprefix=$(BUILD)/ \
		--sym=$(BUILD)/nightshift.sym --lst=$(BUILD)/nightshift.lst \
		src/main.asm

$(FLAGS_FILE): FORCE | $(BUILD)
	@echo '$(ASMFLAGS)' | cmp -s - $@ || echo '$(ASMFLAGS)' > $@

$(BUILD):
	mkdir -p $@

run: $(TAP)
	$(FUSE) --machine 48 $(FUSE_FLAGS) $(TAP)

clean:
	rm -rf $(BUILD)
