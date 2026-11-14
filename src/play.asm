; Play screen (design/play.txt).

    MODULE Play

ATTR        EQU @Screen.WHITE | @Screen.BLACK << 3 | @Screen.BRIGHT

BEST_ROW    EQU 1               ; "Best" line, below the header

start:
    ld a,ATTR
    call @Screen.clear

    call @Header.print_labels   ; row 0: "Level", "Pushes", "Time", ':'

    ; Show the current level (Level.number_bcd).
    ld de,@Alloc.screen_bitmap + @Header.LEVEL_COLUMN   ; row 0
    ld a,(@Level.number_bcd)
    call @Screen.print_digits_2

    ; Row 1: "Best", then the level's best pushes and time, under the
    ; header's.
    ASSERT BEST_ROW < 8
BEST_LINE EQU @Alloc.screen_bitmap + BEST_ROW * 32  ; rows 0-7: just + 32
    ld de,BEST_LINE
    ld hl,best_text
    ld b,BEST_TEXT_LEN
    call @Screen.print_string
    ld de,BEST_LINE + @Header.PUSHES_COLUMN
    ld hl,(@Level.best_pushes)
    call @Screen.print_digits_4
    ld de,BEST_LINE + @Header.TIME_COLUMN
    ld hl,(@Level.best_time)
    call @Screen.print_time
    ld de,BEST_LINE + @Header.TIME_COLUMN + 2
    ld a,':'
    call @Screen.print_char

    call @Input.reset           ; ignore inputs from before the finished screen

event_loop:
    halt
    jr event_loop

best_text:
    DB "Best"
BEST_TEXT_LEN EQU $ - best_text

    ENDMODULE
