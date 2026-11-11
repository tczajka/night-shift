# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Night Shift is a Sokoban-style puzzle game for the ZX Spectrum. The player
pushes crates onto target squares. Crates can be pushed but not pulled, and
only one at a time.

The project is new. See `README.md` for the player-facing description.

## Target hardware constraints

- Z80 CPU at 3.5 MHz; base target is the 48K Spectrum.
- Memory map: ROM 0x0000–0x3FFF, screen bitmap 0x4000–0x57FF, attributes
  0x5800–0x5AFF, and RAM from 0x5B00 upward. The lower 16K of RAM
  (0x4000–0x7FFF) is contended, so put time-critical code and data above
  0x8000.
- Display is 256×192 pixels with one ink/paper attribute per 8×8 cell, so
  colour clash applies. Designing the graphics on an 8×8 or 16×16 grid
  aligned to attribute cells avoids it, which suits a tile-based puzzle game.
- The bitmap is not stored linearly in memory (thirds, character rows, and
  pixel lines are interleaved). Use a lookup table or a helper routine for
  screen addresses.
- Output is a `.tap` image with a BASIC loader followed by a machine-code
  block.

## Toolchain

- **Assembler:** sjasmplus (v1.24.0, at `/usr/local/bin/sjasmplus`). The
  game is written in pure Z80 assembly using sjasmplus syntax.
- **Emulator:** Fuse 1.6.0, GTK build (`fuse-gtk`). Run a tape with
  `fuse-gtk --machine 48 <file>.tap`. 48K is the default machine, but
  passing the flag keeps a machine choice saved in `~/.fuserc` from
  overriding it.

## Build

- `make`: assemble `src/main.asm` into `build/nightshift.tap`, plus a
  symbol table (`build/nightshift.sym`) and listing
  (`build/nightshift.lst`).
- `make run`: build, then run the tape in Fuse as a 48K machine.
- `make clean`: delete `build/`.

The assembler runs with `--syntax=abfw -Wall` (`ASMFLAGS` in the Makefile):
`a` makes `,,` the multi-argument separator (so `sub a,b` is not read as
two instructions), `b` allows parentheses around an operand only for real
memory access, `f` warns on fake (macro-like) instructions, `w` turns
warnings into errors, and `-Wall` enables every optional warning. A build
must produce no warnings.

## Source layout

- `src/main.asm` is the only file passed to sjasmplus. It sets the device,
  `ORG`, and entry point `start`, and includes everything else. Other source
  files are pulled in with `INCLUDE`; binary data with `INCBIN`.
- All game code and data must sit between the `code_start` and `code_end`
  labels in `main.asm`: only that range is saved to tape.
- Wrap each included file in `MODULE <Name>` / `ENDMODULE` so its labels
  become `<Name>.label`. Use `.local` labels inside routines.
- The Makefile rebuilds when any `src/*.asm` changes. Add binary data
  files (or their directory) to the dependencies when introducing `INCBIN`.

## Tape and memory

`src/tape.asm` (included last) builds the tape from two blocks:

1. A BASIC program, autostarting at line 10:
   `10 CLEAR VAL "32767": LOAD "" CODE : RANDOMIZE USR VAL "32768"`.
   Its tokenized bytes are assembled at PROG (0x5CCB) only so `SAVETAP` can
   write them.
2. A CODE block with `code_start`..`code_end`, loaded at 0x8000.

`CLEAR 32767` puts RAMTOP, and therefore the BASIC stack used when the game
starts, just below the code. The two addresses in the BASIC line are text,
so moving `ORG` means editing them too; `ASSERT`s in `tape.asm` fail the
build if they disagree with `code_start` and `start`.

## Open decisions

Record each choice here, and in `README.md` where it affects players, once
it has been made:

- Level data format and level count
- Input scheme (keyboard layout, joystick types)
- Whether to support 128K features (AY sound, extra memory)

## Conventions

- Keep generated artifacts (`.tap`, `.sna`, `.z80`, listings, symbol files)
  out of git.
- Comment non-obvious Z80 code with register usage on entry and exit, plus
  the registers each routine clobbers.
