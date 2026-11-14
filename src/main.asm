; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

    INCLUDE "profile.asm"         ; macros only, no code

    ORG 0x8000                  ; above contended memory

; Everything between code_start and code_end is saved to tape as one CODE
; block. All game code and data must be included inside this range.
code_start:

start:
    di                          ; until initialized; the splash enables them
    ld sp,Alloc.stack_end       ; leave the BASIC stack; no return to BASIC
    call Interrupt.init
    call Level.init
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
code_end:
    INCLUDE "alloc.asm"
    INCLUDE "tape.asm"
