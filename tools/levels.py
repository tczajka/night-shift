#!/usr/bin/env python3
"""Read Sokoban levels in text notation (.sok / .xsb) and print their sizes.

A level is a run of consecutive board lines: lines made only of board
characters and containing at least one wall. Its title is the last other
non-empty line before it, not counting "Key: value" metadata such as
"Author:" (a leading ';' or "Title:" is dropped). Multi-line "Comment:" ...
"Comment-End:" blocks are skipped.

Usage: levels.py FILE...
"""

import re
import sys
from dataclasses import dataclass

# Wall, player, player on target, crate, crate on target, target, floor
# (space, or '-' / '_' in some files).
BOARD_CHARS = set("#@+$*. -_")

METADATA = re.compile(r"[A-Za-z][A-Za-z _-]*:")    # "Author: ...", etc.


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


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__.strip().splitlines()[-1], file=sys.stderr)
        return 2
    for file in sys.argv[1:]:
        for level in read_levels(file):
            print(f"{level.file}:{level.line}: {level.width}x{level.height}"
                  f"  {level.title}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
