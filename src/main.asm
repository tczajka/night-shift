; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

    INCLUDE "profile.asm"         ; macros only, no code

    ORG 0x8000                  ; above contended memory

; Everything between code_start and code_end is saved to tape as one CODE
; block. All game code and data must be included inside this range.
code_start:

start:
    di                          ; no ROM interrupt handler while initializing
    ld sp,Alloc.stack_end       ; leave the BASIC stack; no return to BASIC
    call Interrupt.init
    call Level.init
    ei                          ; initialized: start our frame interrupt
    jp Splash.start

    INCLUDE "memory.asm"
    INCLUDE "math.asm"
    INCLUDE "interrupt.asm"
    INCLUDE "input.asm"
    INCLUDE "screen.asm"
    INCLUDE "header.asm"
    INCLUDE "level.asm"
    INCLUDE "splash.asm"
    INCLUDE "level_select.asm"
    INCLUDE "play.asm"

; The levels, built by tools/levels.py (design/level-format.md): an index of
; 100 offsets from `levels`, then the levels. Last in the code, on a page
; boundary, so the index is within one page and an offset just adds to the
; high byte (see Level.load).
    ALIGN 256
levels:
    INCBIN "../build/levels.bin"
levels_end:
code_end:
    INCLUDE "color.asm"
    INCLUDE "alloc.asm"
    INCLUDE "tape.asm"
