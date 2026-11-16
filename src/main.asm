; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

; Two sections: initialized bytes (code..code_end: all game code and data,
; saved to tape as one CODE block) and uninitialized ones (from uninit: RAM
; set up at run time, see Alloc). code and uninit are where they begin;
; code_cur and uninit_cur are where the next bytes go. Switch between them
; with ORG, saving the current position (DEFL) first.
code        EQU 0x8000          ; above contended memory
uninit      EQU 0xA300
code_cur    DEFL code
uninit_cur  DEFL uninit

    ORG code_cur

    INCLUDE "profile.asm"       ; macros only, no code

    INCLUDE "levels.asm"        ; first: its data is page-aligned
    INCLUDE "start.asm"         ; entry point
    INCLUDE "memory.asm"
    INCLUDE "math.asm"
    INCLUDE "interrupt.asm"
    INCLUDE "input.asm"
    INCLUDE "color.asm"
    INCLUDE "screen.asm"
    INCLUDE "sprite.asm"
    INCLUDE "header.asm"
    INCLUDE "level.asm"
    INCLUDE "splash.asm"
    INCLUDE "level_select.asm"
    INCLUDE "play.asm"
code_end:
    ASSERT code_end <= uninit
    INCLUDE "alloc.asm"
    INCLUDE "tape.asm"
