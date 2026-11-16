# AGENTS.md

Guidance for coding agents working in this repository.

## Project

Night Shift is a Sokoban-style puzzle game for the ZX Spectrum 48K, written
in Z80 assembly. See `README.md` for the player-facing description.

## Toolchain and build

- sjasmplus 1.24.0 (`/usr/local/bin/sjasmplus`); ZEsarUX 13.0, unpacked in
  `~/opt/zesarux-13.0/ZEsarUX-13.0` (needs `libsdl1.2debian`). Fuse is not
  used: its window kept stale pixels after the screen was cleared.
- `make` builds `build/nightshift.tap` (plus `.sym` and `.lst`); `make run`
  runs it in ZEsarUX (`ZESARUX_FLAGS`, `ZESARUX_DIR` to override);
  `make clean`. `--realvideo` makes border colour changes show at their
  real timing, which border profiling needs.
- `tools/levels.py` (Python 3, standard library only) builds
  `build/levels.bin` from `LEVEL_SOURCES` in the Makefile, with a report
  of every level in `build/levels.txt`; `src/main.asm` includes it.
- `make PROFILE=1` (or `make run PROFILE=1`) defines `PROFILE`, enabling
  the `PROFILE_BORDER` colour markers from `src/profile.asm`.
- The assembler flags make warnings errors: a build must produce none.
- Plain `make` only rebuilds on newer timestamps; use `make -B` to be sure.

## Code conventions

- `src/main.asm` is the only file passed to sjasmplus; everything else is
  `INCLUDE`d. Wrap each included file in `MODULE <Name>`; use `.local` labels
  inside routines.
- All game code and data go between `init` and `init_end` in
  `main.asm`: only that range is saved to tape.
- Includes: `profile.asm` (macros) first, then the level data (it must
  start at `init`), then the code, including `color.asm` (constants
  only), then `alloc.asm` and `tape.asm` last.
- Refer to labels in other modules with `@` (e.g. `@Alloc.stack_end`).
  It is required inside a `MODULE`: there a plain reference to a label
  defined later is first taken as module-local, which leaves bogus
  `<Module>.<Other>.*` symbols in the symbol file.
- `Alloc` places every fixed RAM area with `ORG` and `DS`. Before each
  `ORG`, add `ASSERT $ <= <label of the next area>`.
- Add binary files to the Makefile dependencies when introducing `INCBIN`.
- Comment non-obvious routines with register usage on entry and exit, plus
  the registers they clobber.
- Keep generated artifacts out of git.

## Runtime constraints

- The game never returns to BASIC: it replaces the stack and runs in IM 2.
- The ROM's interrupt handler doesn't run, so FRAMES and the ROM keyboard
  variables don't update; IY is free.
- The tape loader disables ROM printing to the main screen (channel S), so
  the game must draw to the screen directly.
- The BASIC loader's addresses are text. The `USR` address is generated
  from `start`, which follows the level data at `0x8000`; the others are
  fixed, and `tape.asm` asserts they match the code, so moving `ORG` means
  editing the loader too.

## Screen design

`design/` holds character-cell mock-ups of each screen and the level
format (`level-format.md`); keep them in sync with the code. Decisions not
visible in them:

- The loading screen (`images/load.scr`, edited directly, not generated)
  doubles as the splash screen (`src/splash.asm`).
- 100 levels, numbered 00–99. The board is 16×11 tiles of 16×16 pixels.
- The game counts pushes (not moves) and time. "Best" is each level's best
  pushes and best time; level select's header shows the selected level's.
- On level select, solved levels and the selected level each have their own
  colour.
- When a level is solved, the header line is highlighted; fire returns to
  level select.
- No undo, by design; Restart is the way out of a dead end.

## Board graphics and animation

The player is a bulldozer pushing crates. Every move (walking or pushing)
slides smoothly to the next tile, so sprites are often not aligned to the
8×8 attribute grid. The colour scheme avoids clash:

- Board paper is bright blue inside the walls and black outside; walls
  are dark red and white (not bright). Everything that moves is ink.
- Bulldozer and crates are bright yellow, the floor cells' ink colour.
  Targets are bright green. Board attributes depend only on the cell
  (floor, target, wall, outside) and never change during play.
- Targets are an ink pattern, inset from the tile edges so the blade never
  touches it. Anything sliding onto a target turns green cell by cell; a
  crate on a target is shown by colour alone.
- Green also marks solved levels and the solved-level header; the selected
  level uses a colour that is neither green nor yellow.
- The crate fills its tile (ink, with a paper-coloured frame and X brace,
  and a paper margin so adjacent crates show a seam). The bulldozer has 4
  rotations and faces its last move; its blade reaches the front tile edge
  so it stays in contact with the crate during a push.
- Bulldozer and crate are drawn as opaque 16×16 blocks by one routine; no
  mask data. Horizontally shifted sprites merge their partial edge bytes
  with an edge mask derived from the shift.
- Each frame, the affected strip (at most 3 tiles) is built off-screen and
  copied to the screen just after the frame interrupt.

## Controls

- Q ↑ A ↓ O ← P →, Space for fire, plus a Kempston joystick if connected
  (`src/input.asm`). No other keys or joysticks.
- Game code reads `Input.held` and takes new presses with
  `Input.get_pressed` (both fed by the frame interrupt); it never reads
  the ports itself.
- Fire chooses a level, opens the pause menu, confirms a menu item, and
  leaves the solved-level screen.
- To test the Kempston path, ZEsarUX can emulate a Kempston joystick
  (`--joystickemulated Kempston`).

## Open decisions

Record each choice here, and in `README.md` where it affects players:

- Animation speed: 2 pixels per frame (8 frames per tile) or 1 (16 frames)
- Whether to support 128K features (AY sound, extra memory)
