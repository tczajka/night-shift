; Play screen (design/play.txt).

    MODULE Play

BEST_ROW    EQU 1               ; "Best" line, below the header
BOARD_ROW   EQU 2               ; character row of the board's top
    ASSERT BOARD_ROW + 2 * @Level.HEIGHT <= 24

NONE        EQU 0xFFFF          ; no number shown yet (not valid BCD)

start:
    call @Level.load

    ld a,@Color.TEXT_ATTR
    call @Screen.clear

    call init_status_lines      ; header and "Best" line
    ld hl,NONE                  ; pushes and time not shown yet: draw shows them
    ld (shown_pushes),hl
    ld (shown_time),hl
    call draw_board

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

; Draw the board (Alloc.board): for now, the walls, each square of wall as
; Sprite.wall in Color.WALL_ATTR. Other squares are left as they are.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw_board:
    ld hl,@Alloc.board          ; L = position
.square:
    ld a,(hl)
    and @Level.WALL
    jr z,.next
    push hl
    ld a,l
    call square_cell
    push bc
    ld hl,@Sprite.wall
    call @Screen.draw_tile
    pop bc
    ld a,@Color.WALL_ATTR
    call @Screen.paint_tile
    pop hl
.next:
    inc l
    ld a,l
    cp @Level.WIDTH * @Level.HEIGHT
    jr nz,.square
    ret

; Character cell of a board square's top left corner: each square is 2x2
; cells, the board starting at row BOARD_ROW, column 0.
; Entry: A = position (row * 16 + column).
; Exit: B = row, C = column.  Clobbers: A.
square_cell:
    ASSERT @Level.WIDTH == 16
    ld c,a                      ; B = BOARD_ROW + 2 * row
    and 0xF0                    ; row * 16
    rrca
    rrca
    rrca                        ; row * 2
    add a,BOARD_ROW
    ld b,a
    ld a,c                      ; C = 2 * column
    and 0x0F
    add a,a
    ld c,a
    ret

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
