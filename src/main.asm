; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

; Two sections: initialized bytes (code..code_end: all game code and data,
; saved to tape as one CODE block) and uninitialized ones (uninit..
; uninit_end: RAM set up at run time, see Alloc). code and uninit are where
; they begin. code_save and uninit_save hold the position reached in each
; while assembling the other: to switch, save the current position (DEFL)
; and ORG to the other's.
code        EQU 0x8000          ; above contended memory
uninit      EQU 0xA000
code_save   DEFL code
uninit_save DEFL uninit

    ORG code

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
    ORG uninit_save
uninit_end:
    ASSERT code_end <= uninit
    INCLUDE "alloc.asm"
    INCLUDE "tape.asm"
