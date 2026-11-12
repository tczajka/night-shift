; Level select screen (design/level-choice.txt).

    MODULE LevelSelect

start:
    halt                        ; start clearing at the top of a frame
    ld a,@Screen.WHITE | @Screen.BLACK << 3 | @Screen.BRIGHT
    call @Screen.clear

    call @Header.print_labels

    ld hl,select_level_text
    ld a,SELECT_LEVEL_TEXT_LEN
    ld bc,1 << 8 | 10           ; row 1, column 10
    call @Screen.print_string

    ld hl,solved_text
    ld a,SOLVED_TEXT_LEN
    ld bc,23 << 8 | 10          ; row 23, column 10
    call @Screen.print_string
.loop:
    halt
    jr .loop

select_level_text:
    DB "Select level"
SELECT_LEVEL_TEXT_LEN EQU $ - select_level_text
solved_text:
    DB "Solved:"
SOLVED_TEXT_LEN EQU $ - solved_text

    ENDMODULE
