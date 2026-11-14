; Memory layout (48K):
;
;   0000-3FFF  ROM
;   4000-57FF  screen bitmap
;   5800-5AFF  screen attributes
;   5B00-7FFF  BASIC
;   8000-....  code (code_start..code_end), loaded from tape
;   E000-FBFF  stack (7KB)
;   FC00-FD8F  high scores
;   FDFD-FDFF  interrupt entry
;   FE00-FF00  interrupt table
;   FF58-FFFF  BASIC
;

    MODULE Alloc

; Screen memory.
screen_bitmap     EQU 0x4000    ; see Screen for the line order
screen_bitmap_end EQU 0x5800
screen_attrs      EQU 0x5800    ; one byte per character cell
screen_attrs_end  EQU 0x5B00

    ASSERT screen_attrs_end <= @code_start
    ASSERT @code_end <= stack

; Stack: SP starts at stack_end (set by `start`) and grows down towards
; stack. Uncontended memory, so pushes and calls run at full speed.
stack           EQU 0xE000
stack_end       EQU 0xFC00

    ASSERT stack_end <= high_scores

; High scores: for each level, best pushes then best time, each
; a little-endian word of 4 BCD digits (time is 0xMMSS, minutes:seconds).
; Level.NO_SCORE in both means the level isn't solved yet; it compares as
; worse than any real score. Set to Level.NO_SCORE by Level.init.
HIGH_SCORE_PUSHES EQU 0         ; offsets within a level's entry
HIGH_SCORE_TIME   EQU 2
HIGH_SCORE_SIZE   EQU 4

high_scores     EQU 0xFC00
high_scores_end EQU high_scores + @Level.COUNT * HIGH_SCORE_SIZE

    ASSERT high_scores_end <= interrupt_entry

; JP to the interrupt handler (3 bytes). Its address must be the same byte
; twice, because every IM 2 vector in the table reads as that address.
interrupt_entry EQU 0xFDFD

; IM 2 vector table: 257 bytes, all equal to the low byte of
; interrupt_entry. Must start on a 256-byte boundary.
interrupt_vectors     EQU 0xFE00
interrupt_vectors_end EQU 0xFF01

    ENDMODULE
