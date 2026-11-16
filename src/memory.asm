; Memory operations.

    MODULE Memory

@code_save DEFL $
    ORG @uninit_save

; Stack: SP starts at stack_end (set by Start.start) and grows down towards
; stack. Uncontended memory, so pushes and calls run at full speed.
    ALIGN 0x100
stack:
    DS 0x2000
stack_end:

@uninit_save DEFL $
    ORG @code_save

; Set a block of memory to one value.
; Entry: HL = start, BC = length (at least 1), A = value.
; Exit: none.  Clobbers: A, BC, DE, HL.
fill:
    ld (hl),a
    dec bc
    ld a,b
    or c
    ret z                       ; a single byte: LDIR would run 65536 times
    ld d,h
    ld e,l
    inc de
    ldir                        ; copy each byte to the next one
    ret

    ENDMODULE
