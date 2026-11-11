; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

    ORG 0x8000                  ; above contended memory

start:
    ei
.loop:
    halt                        ; wait for the next frame interrupt
    jr .loop

    SAVETAP "nightshift.tap", start
