; Memory layout (48K):
;
;   0000-3FFF  ROM
;   4000-57FF  screen bitmap
;   5800-5AFF  screen attributes
;   5B00-7FFF  BASIC
;   8000-....  code (code_start..code_end), loaded from tape
;   9000-918F  high scores
;   E000-EFFF  stack (4KB)
;   FDFD-FDFF  interrupt entry
;   FE00-FF00  interrupt table
;   FF58-FFFF  BASIC
;
; Only the code block is on tape. The areas reserved here are set up at run
; time; ORG and DS just give them addresses. Before each ORG, an ASSERT
; checks that the area before it ends in time.

    MODULE Alloc

; Screen memory.
    ORG 0x4000
screen_bitmap:                  ; see Screen for the line order
    DS 0x1800
screen_bitmap_end:
screen_attrs:                   ; one byte per character cell
    DS 0x300
screen_attrs_end:

    ASSERT $ <= @code_start
    ; code_start..code_end (see main.asm)

    ORG 0x9000
    ASSERT @code_end <= $

; High scores: for each level, best pushes then best time, each
; a little-endian word of 4 BCD digits (time is 0xMMSS, minutes:seconds).
; Level.NO_SCORE in both means the level isn't solved yet; it compares as
; worse than any real score. Set to Level.NO_SCORE by Level.init.
high_scores:
    DS @Level.COUNT * 4
high_scores_end:

    ORG 0xE000
    ASSERT high_scores_end <= $

; Stack: SP starts at stack_end (set by `start`) and grows down towards
; stack. Uncontended memory, so pushes and calls run at full speed.
stack:
    DS 0x1000                   ; 4KB
stack_end:

    ORG 0xFDFD
    ASSERT stack_end <= $

; JP to the interrupt handler (3 bytes). Its address must be the same byte
; twice, because every IM 2 vector in the table reads as that address.
interrupt_entry:
    DS 3

; IM 2 vector table: 257 bytes, all equal to the low byte of
; interrupt_entry. Must start on a 256-byte boundary.
interrupt_vectors:
    ASSERT (interrupt_vectors & 0xFF) == 0
    DS 257
interrupt_vectors_end:

    ENDMODULE
