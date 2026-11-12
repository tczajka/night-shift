; Memory layout (48K):
;
;   0000-3FFF  ROM
;   4000-57FF  screen bitmap
;   5800-5AFF  screen attributes
;   5B00-7FFF  BASIC
;   8000-....  code (code_start..code_end), loaded from tape
;   E000-FCFF  stack (7.25KB)
;   FDFD-FDFF  interrupt entry
;   FE00-FF00  interrupt table
;   FF58-FFFF  BASIC
;
; Only the code block is on tape. The areas reserved here are set up by the
; code at run time; the DS directives just give them addresses.

    MODULE Memory

    ASSERT $ <= stack
    ORG 0xE000

; Stack: SP starts at stack_top (set by `start`) and grows down towards
; stack. Uncontended memory, so pushes and calls run at full speed.
stack:
    DS 0xFD00 - stack
stack_top:

    ASSERT $ <= interrupt_entry       ; the stack must not overlap what follows
    ORG 0xFDFD

; JP to the interrupt handler (3 bytes). Its address must be the same byte
; twice, because every IM 2 vector in the table reads as that address.
interrupt_entry:
    DS 3

; IM 2 vector table: 257 bytes, all equal to the low byte of
; interrupt_entry. Must start on a 256-byte boundary.
interrupt_vectors:
    DS 257

    ENDMODULE
