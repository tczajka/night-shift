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

Each level must fit the 16×11 board, have exactly one player, as many
crates as targets, and be enclosed by walls. There must be exactly 100
levels.

## Cells

A level has three kinds of static cell: empty, wall and target. Cells
outside the walls are never reached and look like floor, so they are
empty too. Crates and the player are placed on top. A crate or the player
on a target is just a position equal to a target's.

A position is one byte: `row * 16 + column`, 0–175, with row 0–10 and
column 0–15.

The script centres each level on the board, so positions are on the
board, and the game does no positioning.

## Layout of a level

n is the number of crates, which equals the number of targets.

| Bytes | Contents |
| --- | --- |
| 1 | n |
| 1 | player position |
| 22 | walls: 11 rows of 2 bytes, 1 bit per cell, set for a wall; in each row the first byte is columns 0–7, bit 7 = leftmost |
| n | target positions |
| n | crate positions |

A level takes 24 + 2n bytes: 32–44 bytes for 4–10 crates, about 4 KB for
all 100.

## Finding a level

Levels are stored one after another, 00 first, with no index. To find
level k, skip k levels, each 24 + 2n bytes long.
