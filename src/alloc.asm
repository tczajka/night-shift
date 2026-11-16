; Memory layout (48K):
;
;   0000-3FFF  ROM
;   4000-57FF  screen bitmap (Screen.bitmap)
;   5800-5AFF  screen attributes (Screen.attrs)
;   5B00-7FFF  BASIC
;   8000-....  code and data (code..code_end), loaded from tape
;   A000-....  uninitialized variables (uninit, see main.asm): high scores
;              (Levels.high_scores), current level (Level.board, ...)
;   E000-EFFF  stack (4KB)
;   FDFD-FDFF  interrupt entry
;   FE00-FF00  interrupt table
;   FF58-FFFF  BASIC
;
; Only the code block is on tape. The areas reserved here are set up at run
; time; ORG and DS just give them addresses. Before each ORG, an ASSERT
; checks that the area before it ends in time.

    MODULE Alloc

    ; code..code_end (see main.asm)
    ; uninit..uninit_end (see main.asm)

    ORG 0xE000
    ASSERT @uninit_end <= $

; Stack: SP starts at stack_end (set by `Start.start`) and grows down
; towards stack. Uncontended memory, so pushes and calls run at full speed.
stack:
    DS 0x1000                   ; 4KB
stack_end:

    ORG 0xFDFD
    ASSERT stack_end <= $

; JP to the interrupt handler (3 bytes). Its address must be the same byte
; twice, because every IM 2 vector in the table reads as that address.
interrupt_entry:
    DS 3

; IM 2 vector table: 0x101 bytes, all equal to the low byte of
; interrupt_entry. Must start on a 0x100-byte boundary.
interrupt_vectors:
    ASSERT (interrupt_vectors & 0xFF) == 0
    DS 0x101
interrupt_vectors_end:

    ENDMODULE
