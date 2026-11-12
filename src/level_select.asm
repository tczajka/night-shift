; Level select screen.

    MODULE LevelSelect

start:
    halt                        ; start clearing at the top of a frame
    ld a,@Screen.WHITE | @Screen.BLACK << 3 | @Screen.BRIGHT
    call @Screen.clear
    ld a,'L'                    ; placeholder: first letter of the header
    ld b,0
    ld c,0
    call @Screen.print_char
.loop:
    halt
    jr .loop

    ENDMODULE
