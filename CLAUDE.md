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

## Open decisions

Record each choice here, and in `README.md` where it affects players, once
it has been made:

- Build system (Makefile) and the build/run commands
- Level data format and level count
- Input scheme (keyboard layout, joystick types)
- Whether to support 128K features (AY sound, extra memory)

## Conventions

- Keep generated artifacts (`.tap`, `.sna`, `.z80`, listings, symbol files)
  out of git.
- Comment non-obvious Z80 code with register usage on entry and exit, plus
  the registers each routine clobbers.
