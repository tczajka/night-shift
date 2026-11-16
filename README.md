# Night Shift

A Sokoban-style puzzle game for the ZX Spectrum.

Push crates onto their target spots to clear each level. You can push a
crate but never pull it, and you can only push one crate at a time, so a
careless move can leave a level unsolvable.

## Status

Early development. There is nothing to build or play yet.

## Target platform

- ZX Spectrum 48K (compatibility with 128K / +2 / +3 to be confirmed)
- Distributed as a `.tap` file that runs in emulators and on real hardware

## Controls

Keyboard, or a Kempston joystick:

| Key | Action |
| --- | --- |
| Q / A / O / P | Up / down / left / right |
| Space | Fire: choose a level, pause, confirm |

A Kempston interface is used whenever one is connected; the keyboard
keeps working alongside it. Cursor and Sinclair joysticks,
including the built-in joystick ports of the +2, +2A and +3, are not
supported.

## Building

Requires [sjasmplus](https://github.com/z00m128/sjasmplus) and GNU Make.

```
make          # builds build/nightshift.tap
make clean    # removes build/
```

## Running

Load `build/nightshift.tap` in a Spectrum emulator. Development uses
[ZEsarUX](https://github.com/chernandezba/zesarux); `make run` builds the
game and starts it in ZEsarUX as a 48K Spectrum.

To set up ZEsarUX on Ubuntu 24.04, unpack the `ubuntu24_x86_64` build from
its [releases](https://github.com/chernandezba/zesarux/releases) into
`~/opt/zesarux-13.0` and install its one missing library with
`sudo apt install libsdl1.2debian`. For another location, use
`make run ZESARUX_DIR=/path/to/ZEsarUX-13.0`.
On real hardware, load the tape with `LOAD ""`.

## Credits

The levels are from Microban, a set of Sokoban puzzles by David W. Skinner
([source](http://www.abelmartin.com/rj/sokobanJS/Skinner/David%20W.%20Skinner%20-%20Sokoban.htm)).

## License

The code is [MIT](LICENSE). The levels (`levels/`) are David W. Skinner's,
under his terms above.
