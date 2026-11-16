# Level format

How the 100 levels are stored in the game. The levels are written in
standard Sokoban text notation, and a build script converts them to this
binary format.

## Source notation

| Character | Cell |
| --- | --- |
| `#` | wall |
| space | floor |
| `.` | target |
| `$` | crate |
| `*` | crate on a target |
| `@` | player |
| `+` | player on a target |

`tools/levels.py` reads the levels in order and uses the first 100 that
fit the 16×11 board. A level that fits only when turned on its side (at
most 11 wide and 16 high) has its x and y swapped, which doesn't change
the puzzle; a level that doesn't fit either way is skipped. Every level
used must have exactly one player, as many crates as targets (at least
one), and be enclosed by walls.

## Cells

A level has three kinds of static cell: empty, wall and target. Cells
outside the walls are never reached and look like floor, so they are
empty too. Crates and the player are placed on top. A crate or the player
on a target is just a position equal to a target's.

A position is one byte: `row * 16 + column`, 0–175, with row 0–10 and
column 0–15.

The script centres each level on the board, so positions are on the
board, and the game does no positioning.

## Layout of the level data

| Bytes | Contents |
| --- | --- |
| 200 | index: 100 little-endian words, the offset of each level (00 first) from the start of the level data |
| ... | the levels, one after another |

The offsets are from the start of the data rather than addresses, so the
script doesn't need to know where the data will be loaded: the game adds
the address of the data. Level k's offset is at offset 2k.

## Layout of a level

n is the number of crates, which equals the number of targets.

| Bytes | Contents |
| --- | --- |
| 1 | n |
| 1 | player position |
| 22 | walls: 11 rows of 2 bytes, 1 bit per cell, set for a wall; in each row the first byte is columns 0–7, bit 7 = leftmost |
| n | target positions |
| n | crate positions |

A level takes 24 + 2n bytes: 32–44 bytes for 4–10 crates. All 100 take
about 4 KB, plus 200 bytes for the index.
