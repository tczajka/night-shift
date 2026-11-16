; Interrupt handling: replaces the ROM's IM 1 handler with our own, in IM 2.
;
; In IM 2 the Z80 jumps through a vector read from I * 0x100 + (data bus
; byte). On the Spectrum the data bus value during the interrupt is not
; reliable, so the vector table (`vectors`) is 0x101 bytes all set to
; VECTOR_BYTE: every possible vector then reads `entry`, where a JP to the
; handler is placed. Both are built at run time, so they take no space on
; tape.
;
; I must not point into 0x4000-0x7FFF: on a 48K that makes the ULA show
; "snow" on the screen.

    MODULE Interrupt

@code_save DEFL $
    ORG 0xFDFD

; JP to the handler (3 bytes). Its address must be the same byte twice,
; because every IM 2 vector in the table reads as that address.
entry:
    DS 3

; IM 2 vector table: 0x101 bytes, all equal to the low byte of `entry`.
; Must start on a 0x100-byte boundary.
vectors:
    DS 0x101
vectors_end:

    ORG @code_save

VECTOR_BYTE EQU entry & 0xFF

    ASSERT vectors >= 0x8000
    ASSERT (vectors & 0xFF) == 0
    ASSERT entry >> 8 == VECTOR_BYTE

; Install the handler and switch to IM 2. Interrupts must be disabled, and
; stay disabled: the caller enables them when ready.
; Entry: interrupts disabled.  Exit: none.  Clobbers: A, BC, DE, HL.
init:
    ld hl,vectors
    ld bc,vectors_end - vectors
    ld a,VECTOR_BYTE
    call @Memory.fill           ; fill all 0x101 bytes
    ld a,0xC3                   ; JP nn
    ld (entry),a
    ld hl,handler
    ld (entry + 1),hl
    ld a,vectors >> 8
    ld i,a
    im 2
    ret

; Frame interrupt, 50 times a second. Runs at the top of the frame, before
; the ULA starts drawing the picture.
; Must preserve every register it uses.
handler:
    push af
    push bc
    push hl
    call @Input.scan
    call @Level.time_tick
    pop hl
    pop bc
    pop af
    ei
    reti

    ENDMODULE
