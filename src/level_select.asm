; Level select screen (design/level-select.txt).

    MODULE LevelSelect

start:
    ld a,@Screen.WHITE | @Screen.BLACK << 3 | @Screen.BRIGHT
    call @Screen.clear

    call @Header.print_labels   ; row 0: "Level", "Pushes", "Time", ':'

    ; "Select level"
    ld bc,1 << 8 | 10           ; row 1, column 10
    call @Screen.char_address
    ld hl,select_level_text
    ld b,SELECT_LEVEL_TEXT_LEN
    call @Screen.print_string

    ; "Solved: 000"
    ld bc,23 << 8 | 10          ; row 23, column 10
    call @Screen.char_address
    ld hl,solved_text           ; "Solved:"
    ld b,SOLVED_TEXT_LEN
    call @Screen.print_string
    inc e                       ; skip a space
    ld hl,(@Level.solved_bcd)   ; number of solved levels
    call @Screen.print_digits_3

    call @Input.reset           ; ignore inputs from before the finished screen
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
