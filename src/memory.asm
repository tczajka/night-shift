; Memory block operations.

    MODULE Memory

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
