; Night Shift - a Sokoban-style puzzle game for the ZX Spectrum 48K.
; Top-level source file: other source files are pulled in with INCLUDE.

    DEVICE ZXSPECTRUM48

; Memory layout (48K):
;
;   0000-3FFF  ROM
;   4000-57FF  screen bitmap (Screen.bitmap)
;   5800-5AFF  screen attributes (Screen.attrs)
;   5B00-7FFF  BASIC
;   8000-....  code and data (code..code_end), loaded from tape
;   A000-....  uninitialized (uninit..uninit_end): high scores
;              (Levels.high_scores), stack (Memory.stack), current level
;              (Level.board, ...)
;   FDFD-FDFF  interrupt entry (Interrupt.entry)
;   FE00-FF00  interrupt table (Interrupt.vectors)
;   FF58-FFFF  BASIC
;
; Two sections: initialized bytes (code..code_end: all game code and data,
; saved to tape as one CODE block) and uninitialized ones (uninit..
; uninit_end: RAM set up at run time). code and uninit are where they
; begin. code_save and uninit_save hold the position reached in each while
; assembling the other: to switch, save the current position (DEFL) and
; ORG to the other's. Areas at fixed addresses (screen memory, the
; interrupt table) are reserved the same way, with ORG and DS, in their
; modules; ORG and DS only give them addresses.
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
    ASSERT uninit_end <= Interrupt.entry
    INCLUDE "tape.asm"
