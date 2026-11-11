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

To be decided. The likely default is QAOP + Space, with Sinclair and
Kempston joystick support.

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
