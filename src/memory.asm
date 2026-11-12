; Memory layout (48K):
;
;   0x0000-0x3FFF  ROM
;   0x4000-0x5AFF  screen (bitmap, then attributes)
;   0x5B00-0x7FFF  system variables, BASIC loader, stack (below RAMTOP 0x7FFF)
;   0x8000-...     code block (code_start..code_end), loaded from tape
;   0xFDFD-0xFF00  IM 2 interrupt entry and vector table, built at run time
;
; Only the code block is on tape. The areas reserved here are set up by the
; code at run time; the DS directives just give them addresses.

    MODULE Memory

    ASSERT @code_end <= interrupt_entry

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
