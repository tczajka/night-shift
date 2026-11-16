; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

    INCLUDE "profile.asm"         ; macros only, no code

; Two sections: initialized bytes (init..init_end: all game code and data,
; saved to tape as one CODE block) and uninitialized ones (from uninit: RAM
; set up at run time, see Alloc). init and uninit are where they begin;
; init_cur and uninit_cur are where the next bytes go. Switch between them
; with ORG, saving the current position (DEFL) first.
init        EQU 0x8000          ; above contended memory
uninit      EQU 0xA300
init_cur    DEFL init
uninit_cur  DEFL uninit

    ORG init_cur

; The levels, built by tools/levels.py (design/level-format.md): an index of
; 100 offsets from `levels`, then the levels. First in the code, so they
; start on a page boundary: the index is within one page and an offset just
; adds to the high byte (see Level.load).
levels:
    INCBIN "../build/levels.bin"
levels_end:

; Entry point, called by the BASIC loader (see tape.asm).
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
    INCLUDE "sprite.asm"
    INCLUDE "header.asm"
    INCLUDE "level.asm"
    INCLUDE "splash.asm"
    INCLUDE "level_select.asm"
    INCLUDE "play.asm"
init_end:
init_cur DEFL $                 ; the end of the initialized section
    INCLUDE "color.asm"
    INCLUDE "alloc.asm"
    INCLUDE "tape.asm"

    ASSERT init_cur <= uninit
