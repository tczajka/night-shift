; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

    ORG 0x8000                  ; above contended memory

; Everything between code_start and code_end is saved to tape as one CODE
; block. All game code and data must be included inside this range.
code_start:

start:
    ld sp,Memory.stack_top     ; leave the BASIC stack; no return to BASIC
    call Interrupt.init
.loop:
    halt                        ; wait for the next frame interrupt
    jr .loop

    INCLUDE "interrupt.asm"
code_end:
    INCLUDE "memory.asm"
    INCLUDE "tape.asm"
