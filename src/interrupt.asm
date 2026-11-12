; Interrupt handling: replaces the ROM's IM 1 handler with our own, in IM 2.
;
; In IM 2 the Z80 jumps through a vector read from I * 256 + (data bus
; byte). On the Spectrum the data bus value during the interrupt is not
; reliable, so the vector table (Memory.interrupt_vectors) is 257 bytes all
; set to VECTOR_BYTE: every possible vector then reads Memory.interrupt_entry,
; where a JP to the handler is placed. Both are built at run time, so they
; take no space on tape.
;
; I must not point into 0x4000-0x7FFF: on a 48K that makes the ULA show
; "snow" on the screen.

    MODULE Interrupt

VECTOR_BYTE EQU Memory.interrupt_entry & 0xFF

    ASSERT Memory.interrupt_vectors >= 0x8000
    ASSERT (Memory.interrupt_vectors & 0xFF) == 0
    ASSERT Memory.interrupt_entry >> 8 == VECTOR_BYTE

; Install the handler and enable interrupts in IM 2.
; Entry: none.  Exit: interrupts enabled.  Clobbers: A, BC, DE, HL.
init:
    di
    ld hl,Memory.interrupt_vectors
    ld de,Memory.interrupt_vectors + 1
    ld bc,256
    ld (hl),VECTOR_BYTE
    ldir                        ; fill all 257 bytes
    ld a,0xC3                   ; JP nn
    ld (Memory.interrupt_entry),a
    ld hl,handler
    ld (Memory.interrupt_entry + 1),hl
    ld a,Memory.interrupt_vectors >> 8
    ld i,a
    im 2
    ei
    ret

; Frame interrupt, 50 times a second. Does nothing yet.
; Must preserve every register it uses.
handler:
    ei
    reti

    ENDMODULE
