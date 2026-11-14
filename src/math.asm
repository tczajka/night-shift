; Arithmetic helpers.

    MODULE Math

; Convert a 2-digit binary coded decimal number to binary.
; Entry: A = number in BCD (0x00-0x99).
; Exit: A = the same number in binary (0-99).  Clobbers: B, C.
from_bcd:
    ld b,a
    and 0xF0                    ; high digit * 16
    rrca                        ; * 8
    ld c,a
    rrca
    rrca                        ; * 2
    add a,c                     ; * 10
    ld c,a
    ld a,b
    and 0x0F                    ; low digit
    add a,c
    ret

    ENDMODULE
