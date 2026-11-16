#!/usr/bin/env python3
"""Convert Sokoban levels in text notation (.sok / .xsb) to the game's level
data (design/level-format.md).

Levels are read from the files in order. A level too big for the 16x11
board is skipped, unless it fits when turned on its side: then its x and y
are swapped. The first 100 levels that fit are written to OUTPUT.

A level is a run of consecutive board lines: lines made only of board
characters and containing at least one wall. Its title is the last other
non-empty line before it, not counting "Key: value" metadata such as
"Author:" (a leading ';' or "Title:" is dropped). Multi-line "Comment:" ...
"Comment-End:" blocks are skipped.

Usage: levels.py OUTPUT FILE...
"""

import re
import sys
from dataclasses import dataclass

# Wall, player, player on target, crate, crate on target, target, floor
# (space, or '-' / '_' in some files).
BOARD_CHARS = set("#@+$*. -_")

METADATA = re.compile(r"[A-Za-z][A-Za-z _-]*:")    # "Author: ...", etc.

BOARD_WIDTH = 16
BOARD_HEIGHT = 11
LEVEL_COUNT = 100
INDEX_SIZE = 2 * LEVEL_COUNT    # a little-endian word per level


class LevelError(Exception):
    pass


@dataclass
class Level:
    file: str
    line: int          # line number of the first board line, from 1
    title: str
    rows: list[str]    # board lines, with the common left margin removed

    @property
    def width(self) -> int:
        return max(len(row) for row in self.rows)

    @property
    def height(self) -> int:
        return len(self.rows)

    def name(self) -> str:
        return f"{self.file}:{self.line} ({self.title})"

    def grid(self) -> list[str]:
        """The rows, padded to the same width, with every floor as ' '."""
        return [row.replace("-", " ").replace("_", " ").ljust(self.width)
                for row in self.rows]

    def transposed(self) -> "Level":
        grid = self.grid()
        rows = ["".join(row[x] for row in grid).rstrip()
                for x in range(self.width)]
        return Level(self.file, self.line, self.title, rows)


def is_board_line(line: str) -> bool:
    return "#" in line and set(line) <= BOARD_CHARS


def clean_title(line: str) -> str:
    line = line.strip()
    if line.startswith(";"):
        line = line[1:].strip()
    if line.lower().startswith("title:"):
        line = line[len("title:"):].strip()
    return line


def make_level(file: str, line: int, title: str, rows: list[str]) -> Level:
    # Floor at either end of a row is outside the walls: not part of the size.
    rows = [row.rstrip(" -_") for row in rows]
    margin = min(len(row) - len(row.lstrip(" -_")) for row in rows)
    return Level(file, line, title, [row[margin:] for row in rows])


def read_levels(file: str) -> list[Level]:
    levels = []
    title = ""
    rows: list[str] = []
    start = 0
    in_comment = False

    with open(file, encoding="utf-8", errors="replace") as f:
        for number, line in enumerate(f, start=1):
            line = line.rstrip("\r\n").rstrip()
            key = line.strip().lower()

            if in_comment:
                if key.startswith("comment-end:") or key.startswith("comment_end:"):
                    in_comment = False
                continue

            if is_board_line(line):
                if not rows:
                    start = number
                rows.append(line)
                continue

            if rows:                        # the board just ended
                levels.append(make_level(file, start, title, rows))
                rows = []
                title = ""

            if key == "comment:":
                in_comment = True
            elif key.startswith("title:") or (key and not METADATA.match(key)):
                title = clean_title(line)

    if rows:
        levels.append(make_level(file, start, title, rows))
    return levels


def fits(level: Level) -> bool:
    return level.width <= BOARD_WIDTH and level.height <= BOARD_HEIGHT


def check(level: Level, grid: list[str]) -> None:
    """Raise LevelError unless the level is playable: one player, as many
    crates as targets (at least one), and enclosed by walls."""
    players = [(x, y) for y, row in enumerate(grid)
               for x, c in enumerate(row) if c in "@+"]
    crates = sum(row.count("$") + row.count("*") for row in grid)
    targets = sum(row.count(".") + row.count("+") + row.count("*")
                  for row in grid)
    if len(players) != 1:
        raise LevelError(f"{len(players)} players")
    if crates != targets:
        raise LevelError(f"{crates} crates but {targets} targets")
    if crates == 0:
        raise LevelError("no crates")

    # Everything the player can reach must be inside the walls, and so must
    # every crate and target.
    reached = set()
    todo = [players[0]]
    while todo:
        x, y = todo.pop()
        if (x, y) in reached:
            continue
        if not (0 <= y < len(grid) and 0 <= x < len(grid[y])):
            raise LevelError("not enclosed by walls")
        if grid[y][x] == "#":
            continue
        reached.add((x, y))
        todo += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    for y, row in enumerate(grid):
        for x, c in enumerate(row):
            if c in "$*." and (x, y) not in reached:
                raise LevelError(f"crate or target outside the walls at "
                                 f"row {y + 1}, column {x + 1}")


def encode(level: Level) -> bytes:
    """A level in the game's format, centred on the board."""
    grid = level.grid()
    check(level, grid)
    left = (BOARD_WIDTH - level.width) // 2
    top = (BOARD_HEIGHT - level.height) // 2

    walls = bytearray(BOARD_HEIGHT * BOARD_WIDTH // 8)
    targets = []
    crates = []
    player = 0
    for y, row in enumerate(grid):
        for x, c in enumerate(row):
            row_on_board, column = top + y, left + x
            position = row_on_board * BOARD_WIDTH + column
            if c == "#":
                walls[position // 8] |= 0x80 >> (column % 8)
            if c in ".+*":
                targets.append(position)
            if c in "$*":
                crates.append(position)
            if c in "@+":
                player = position
    return bytes([len(crates), player]) + walls + bytes(targets + crates)


def main() -> int:
    if len(sys.argv) < 3:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    output, files = sys.argv[1], sys.argv[2:]

    levels = []         # encoded levels that fit
    skipped = flipped = 0
    for file in files:
        for level in read_levels(file):
            size = f"{level.width}x{level.height}"
            if not fits(level):
                if not fits(level.transposed()):
                    print(f"{level.name()}: {size}, skipped: too big")
                    skipped += 1
                    continue
                level = level.transposed()
                size += ", x and y swapped"
                flipped += 1
            try:
                levels.append(encode(level))
            except LevelError as e:
                print(f"{level.name()}: error: {e}", file=sys.stderr)
                return 1
            number = len(levels) - 1
            use = (f"level {number:02d}" if number < LEVEL_COUNT
                   else "not needed")
            print(f"{level.name()}: {size}, {use}")

    if len(levels) < LEVEL_COUNT:
        print(f"error: only {len(levels)} levels fit, {LEVEL_COUNT} needed",
              file=sys.stderr)
        return 1
    unused = len(levels) - LEVEL_COUNT
    levels = levels[:LEVEL_COUNT]

    index = bytearray()
    offset = INDEX_SIZE
    for level in levels:
        index += offset.to_bytes(2, "little")
        offset += len(level)
    data = bytes(index) + b"".join(levels)
    with open(output, "wb") as f:
        f.write(data)

    print(f"{output}: {LEVEL_COUNT} levels, {len(data)} bytes "
          f"({flipped} with x and y swapped, {skipped} too big, "
          f"{unused} more not needed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
