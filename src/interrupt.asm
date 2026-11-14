; Interrupt handling: replaces the ROM's IM 1 handler with our own, in IM 2.
;
; In IM 2 the Z80 jumps through a vector read from I * 256 + (data bus
; byte). On the Spectrum the data bus value during the interrupt is not
; reliable, so the vector table (Alloc.interrupt_vectors) is 257 bytes all
; set to VECTOR_BYTE: every possible vector then reads Alloc.interrupt_entry,
; where a JP to the handler is placed. Both are built at run time, so they
; take no space on tape.
;
; I must not point into 0x4000-0x7FFF: on a 48K that makes the ULA show
; "snow" on the screen.

    MODULE Interrupt

VECTOR_BYTE EQU @Alloc.interrupt_entry & 0xFF

    ASSERT @Alloc.interrupt_vectors >= 0x8000
    ASSERT (@Alloc.interrupt_vectors & 0xFF) == 0
    ASSERT @Alloc.interrupt_entry >> 8 == VECTOR_BYTE

; Install the handler and switch to IM 2. Interrupts must be disabled, and
; stay disabled: the caller enables them when ready.
; Entry: interrupts disabled.  Exit: none.  Clobbers: A, BC, DE, HL.
init:
    ld hl,@Alloc.interrupt_vectors
    ld bc,@Alloc.interrupt_vectors_end - @Alloc.interrupt_vectors
    ld a,VECTOR_BYTE
    call @Memory.fill           ; fill all 257 bytes
    ld a,0xC3                   ; JP nn
    ld (@Alloc.interrupt_entry),a
    ld hl,handler
    ld (@Alloc.interrupt_entry + 1),hl
    ld a,@Alloc.interrupt_vectors >> 8
    ld i,a
    im 2
    ret

; Frame interrupt, 50 times a second. Runs at the top of the frame, before
; the ULA starts drawing the picture.
; Must preserve every register it uses.
handler:
    push af
    push bc
    call @Input.scan
    pop bc
    pop af
    ei
    reti

    ENDMODULE
