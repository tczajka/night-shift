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

Cursor keys, a cursor (Protek/AGF) joystick, or a Kempston joystick:

| Key | Action |
| --- | --- |
| 5 / 6 / 7 / 8 | Left / down / up / right |
| 0 | Fire: choose a level, pause, confirm |

Caps Shift is optional, so the cursor keys work both as plain 5–8 and as
Caps Shift + 5–8 (the dedicated cursor keys on later models).

A Kempston interface is detected automatically when the game starts; the
keyboard keeps working alongside it. Sinclair joysticks, including the
built-in joystick ports of the +2, +2A and +3, are not supported.

## Building

Requires [sjasmplus](https://github.com/z00m128/sjasmplus) and GNU Make.

```
make          # builds build/nightshift.tap
make clean    # removes build/
```

## Running

Load `build/nightshift.tap` in a Spectrum emulator. Development uses
[Fuse](https://fuse-emulator.sourceforge.net/); `make run` builds the game
and starts it in Fuse as a 48K Spectrum.

On Ubuntu, install Fuse with
`sudo apt install fuse-emulator-gtk spectrum-roms`.
On real hardware, load the tape with `LOAD ""`.

## License

[MIT](LICENSE)
