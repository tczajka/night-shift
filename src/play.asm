; Play screen (design/play.txt).

    MODULE Play

BEST_ROW    EQU 1               ; "Best" line, below the header

NONE        EQU 0xFFFF          ; no number shown yet (not valid BCD)

start:
    call @Level.load

    ld a,@Color.TEXT_ATTR
    call @Screen.clear

    call init_status_lines      ; header and "Best" line
    ld hl,NONE                  ; pushes and time not shown yet: draw shows them
    ld (shown_pushes),hl
    ld (shown_time),hl

    call @Input.reset           ; ignore inputs from before the finished screen

    ld a,1                      ; start the time
    ld (@Level.time_running),a

event_loop:
    halt
    PROFILE_BORDER @Color.BLUE     ; drawing
    call draw
    PROFILE_BORDER @Color.RED      ; processing after the draw (none yet)
    PROFILE_BORDER @Color.BLACK    ; idle until the next frame
    jr event_loop

; Set up the status lines at the top: the header (row 0) with the level
; number, and the "Best" line (row 1). The pushes and time in the header
; are left to draw.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
init_status_lines:
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
    jp @Screen.print_char

; Show the level's pushes and time (Alloc.pushes, Alloc.time) in the
; header, each only if it has changed since it was last shown.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw:
    ; show pushes
    ld hl,(@Alloc.pushes)
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
    ld hl,(@Alloc.time)
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
