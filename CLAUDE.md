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

## Screen design

`design/` holds character-cell mock-ups of each screen (32×24 cells):
`splash.txt` (loading/splash screen), `level.txt` (play), `pause.txt` (pause
menu), `level-choice.txt` (level select). Keep them in sync with the code.
Decisions not visible in them:

- The loading screen doubles as the splash screen. It is a picture loaded
  from tape before the code; when the code starts, the picture is still in
  screen memory, so the game just waits for fire and then goes to level
  select. The GitHub URL is part of the picture, on the bottom character row
  (centred, columns 1–30), kept clear of the art so its attributes don't
  clash. Not implemented yet: the tape has no screen block so far.
- 100 levels, numbered 00–99.
- The board is 16×11 tiles of 16×16 pixels (2×2 character cells each), below
  two header rows. See "Board graphics and animation" for how it is drawn.
- The game counts pushes, not moves, plus elapsed time. "Best" holds each
  level's best pushes and best time.
- On level select, the header shows the selected level's best scores. Solved
  levels and the selected level are each shown in their own colour. The
  bottom row shows how many levels are solved (`Solved: 000`, three digits
  because all 100 can be solved).
- The pause box (12×5) sits on columns 10–21, rows 10–14: centred on the
  board (8 board rows above, 9 below, as 5 rows cannot split 22 evenly).
  `pause.txt` draws the board as dots to show this.
- When a level is solved, the top header line is highlighted and the game
  waits for fire, then returns to level select.
- There is no undo, by design; Restart is the way out of a dead end.

## Board graphics and animation

The player is a bulldozer that pushes crates. Every move is animated: the
bulldozer, and the crate it pushes, slide smoothly to the next tile. While
sliding, a 16×16 sprite is not aligned to the 8×8 attribute grid, so the
colour scheme is built to avoid clash:

- The board's paper is black everywhere except on walls, and everything that
  moves, plus targets, is drawn in ink. Black looks the same with and without
  BRIGHT, so cells can freely mix bright and normal ink colours.
- Colours: bulldozer and crates bright yellow, targets bright green, walls
  red and white. Green also marks solved levels on level select and the
  header when a level is solved; the selected level uses a colour that is
  neither green nor yellow.
- Walls can use any ink and paper: nothing ever moves into a wall tile.
- The bulldozer and crates share one ink colour (yellow), which is the
  floor cells' ink. Every cell's attribute therefore depends only on what
  the board has there (floor, target, wall): board attributes are set when a
  level is drawn and never change during play, and there is no clash.
- Targets are an ink pattern (e.g. a dotted square) on black, inset from the
  tile edges (e.g. pixels 2–13) so the bulldozer's blade never touches it.
  Target cells always use the target ink colour (green), so a bulldozer or
  crate turns green cell by cell as it slides onto a target, and back as it
  slides off. A crate on a target is therefore shown by colour alone, with
  no extra graphics.
- A crate fills the whole 16×16 tile: mostly ink pixels, with its frame and
  planks drawn as black (paper) lines, so it looks solid and two adjacent
  crates show a 2-pixel seam.
- The bulldozer has 4 rotations and faces the direction of its last move. Its
  blade reaches the tile edge at the front, so it stays in contact with the
  crate throughout a push. Its other sides keep a small margin.
- The bulldozer and crate are both drawn as opaque 16×16 blocks: they
  replace everything under them, including the target pattern (their colour
  already shows they are on a target). There is no per-sprite mask data, and
  one routine draws both.
- Each animation frame builds the affected strip of tiles off-screen (at most
  3 tiles: 48×16 or 16×48 pixels) and copies it to the screen just after the
  frame interrupt: floor and target tiles first, then the crate and
  bulldozer. Walking moves animate the same way as pushes.
- Vertical movement keeps sprites byte-aligned. Horizontal movement shifts
  them by a non-multiple of 8 pixels, so each row spans 3 bytes. The partly
  covered first and last bytes are merged with the background using an edge
  mask that depends only on the shift (e.g. `0xFF >> shift`).

## Controls

Cursor keys and the cursor (Protek/AGF) joystick only: directions are keys
5 ← 6 ↓ 7 ↑ 8 →, fire is 0. No other joystick interfaces or redefinable
keys.

- Read the keys from half-rows 0xF7FE (bit 4 = 5) and 0xEFFE (bit 0 = 0,
  bit 1 = 9, bit 2 = 8, bit 3 = 7, bit 4 = 6); a pressed key reads as 0.
  Ignore Caps Shift, so both 5–8 and Caps Shift + 5–8 (what the dedicated
  cursor keys on the Spectrum+ and later models send) work.
- Fire chooses a level on level select, opens the pause menu during play,
  confirms the selected pause-menu item, and leaves the solved-level
  screen.

## Open decisions

Record each choice here, and in `README.md` where it affects players, once
it has been made:

- Level data format
- Animation speed: 2 pixels per frame (8 frames, 0.16 s per tile) or 1 pixel
  per frame (16 frames, 0.32 s)
- Whether to support 128K features (AY sound, extra memory)

## Conventions

- Keep generated artifacts (`.tap`, `.sna`, `.z80`, listings, symbol files)
  out of git.
- Comment non-obvious Z80 code with register usage on entry and exit, plus
  the registers each routine clobbers.
