# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

Night Shift is a Sokoban-style puzzle game for the ZX Spectrum 48K, written
in Z80 assembly. See `README.md` for the player-facing description.

## Toolchain and build

- sjasmplus 1.24.0 (`/usr/local/bin/sjasmplus`); Fuse 1.6.0 (`fuse-gtk`).
- `make` builds `build/nightshift.tap` (plus `.sym` and `.lst`); `make run`
  runs it in Fuse (`FUSE_FLAGS` to override options); `make clean`.
- The assembler flags make warnings errors: a build must produce none.
- Plain `make` only rebuilds on newer timestamps; use `make -B` to be sure.

## Code conventions

- `src/main.asm` is the only file passed to sjasmplus; everything else is
  `INCLUDE`d. Wrap each included file in `MODULE <Name>`; use `.local` labels
  inside routines.
- All game code and data go between `code_start` and `code_end` in
  `main.asm`: only that range is saved to tape.
- `memory.asm` is included before the code so its labels are defined before
  use; otherwise sjasmplus leaves bogus `<Module>.Memory.*` symbols. Areas
  reserved there take no tape space.
- sjasmplus does not detect overlapping `ORG` regions: every `ORG` in
  `Memory` needs an `ASSERT $ <= <label of the next region>` before it.
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
- The BASIC loader's addresses are text; `tape.asm` asserts they match the
  code, so moving `ORG` means editing the loader too.

## Screen design

`design/` holds character-cell mock-ups of each screen; keep them in sync
with the code. Decisions not visible in them:

- The loading screen (`images/load.scr`, edited directly, not generated)
  doubles as the splash screen: when the code starts it is still on screen,
  so the game waits for fire, then goes to level select.
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

- Board paper is black everywhere except walls; everything else is ink.
- Bulldozer and crates are bright yellow, the floor cells' ink colour.
  Targets are bright green, walls red and white. Board attributes depend
  only on the cell (floor, target, wall) and never change during play.
- Targets are an ink pattern, inset from the tile edges so the blade never
  touches it. Anything sliding onto a target turns green cell by cell; a
  crate on a target is shown by colour alone.
- Green also marks solved levels and the solved-level header; the selected
  level uses a colour that is neither green nor yellow.
- The crate fills its tile (ink, with black frame and plank lines, so
  adjacent crates show a seam). The bulldozer has 4 rotations and faces its
  last move; its blade reaches the front tile edge so it stays in contact
  with the crate during a push.
- Bulldozer and crate are drawn as opaque 16×16 blocks by one routine; no
  mask data. Horizontally shifted sprites merge their partial edge bytes
  with an edge mask derived from the shift.
- Each frame, the affected strip (at most 3 tiles) is built off-screen and
  copied to the screen just after the frame interrupt.

## Controls

- Q ↑ A ↓ O ← P →, Space for fire, always active; plus a Kempston joystick
  if detected at startup. No other keys or joysticks.
- Internally, input uses the Kempston layout (bits 0–4 right, left, down,
  up, fire; 1 = pressed): convert the keys into it and OR in the Kempston
  value.
- Kempston detection: read port 31 right after `halt` (top border). With no
  interface it reads 0xFF; a Kempston returns bits 5–7 as 0. Require that on
  several consecutive frames. Never read port 31 otherwise without an
  interface: on a 48K it returns screen bytes during the display.
- Fire chooses a level, opens the pause menu, confirms a menu item, and
  leaves the solved-level screen.
- In Fuse, `FUSE_FLAGS="-g 3x --kempston --joystick-keyboard-output 2"` sends
  Q/A/O/P/Space through the Kempston interface instead of as keys.

## Open decisions

Record each choice here, and in `README.md` where it affects players:

- Level data format
- Animation speed: 2 pixels per frame (8 frames per tile) or 1 (16 frames)
- Whether to support 128K features (AY sound, extra memory)
