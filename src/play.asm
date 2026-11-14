; Play screen (design/play.txt).

    MODULE Play

ATTR        EQU @Screen.WHITE | @Screen.BLACK << 3 | @Screen.BRIGHT

BEST_ROW    EQU 1               ; "Best" line, below the header

NONE        EQU 0xFFFF          ; no number shown yet (not valid BCD)

start:
    ld a,ATTR
    call @Screen.clear

    call @Header.print_labels   ; row 0: "Level", "Pushes", "Time", ':'

    ; Show the current level (Level.number_bcd).
    ld de,@Alloc.screen_bitmap + @Header.LEVEL_COLUMN   ; row 0
    ld a,(@Level.number_bcd)
    call @Screen.print_digits_2

    ; Row 1: the level's best pushes and time, each under the header's
    ; and labelled "Best" under "Pushes" and "Time".
    ASSERT BEST_ROW < 8
BEST_LINE EQU @Alloc.screen_bitmap + BEST_ROW * 32  ; rows 0-7: just + 32
    ld de,BEST_LINE + @Header.PUSHES_LABEL_COLUMN
    ld hl,best_text
    ld b,BEST_TEXT_LEN
    call @Screen.print_string
    ld de,BEST_LINE + @Header.PUSHES_COLUMN
    ld hl,(@Level.best_pushes)
    call @Screen.print_digits_4
    ld de,BEST_LINE + @Header.TIME_LABEL_COLUMN
    ld hl,best_text
    ld b,BEST_TEXT_LEN
    call @Screen.print_string
    ld de,BEST_LINE + @Header.TIME_COLUMN
    ld hl,(@Level.best_time)
    call @Screen.print_time
    ld de,BEST_LINE + @Header.TIME_COLUMN + 2
    ld a,':'
    call @Screen.print_char

    ld hl,0                     ; no pushes, no time yet
    ld (@Level.pushes),hl
    ld (@Level.time),hl
    ld hl,NONE                  ; not shown yet: draw shows them
    ld (shown_pushes),hl
    ld (shown_time),hl

    call @Input.reset           ; ignore inputs from before the finished screen

event_loop:
    halt
    call draw
    jr event_loop

; Show the level's pushes and time (Level.pushes, Level.time) in the
; header, each only if it has changed since it was last shown.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw:
    ; show pushes
    ld hl,(@Level.pushes)
    ld de,(shown_pushes)
    or a
    sbc hl,de
    jr z,.pushes_done
    add hl,de                   ; HL = pushes again
    ld (shown_pushes),hl
    ld de,@Alloc.screen_bitmap + @Header.PUSHES_COLUMN  ; row 0
    call @Screen.print_digits_4
.pushes_done:
    ; show time
    ld hl,(@Level.time)
    ld de,(shown_time)
    or a
    sbc hl,de
    ret z
    add hl,de                   ; HL = time again
    ld (shown_time),hl
    ld de,@Alloc.screen_bitmap + @Header.TIME_COLUMN
    jp @Screen.print_time

best_text:
    DB "Best"
BEST_TEXT_LEN EQU $ - best_text

shown_pushes: DW NONE           ; pushes shown in the header, or NONE
shown_time:   DW NONE           ; time shown in the header, or NONE

    ENDMODULE
