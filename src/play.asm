; Play screen (design/play.txt).

    MODULE Play

BEST_ROW    EQU 1               ; "Best" line, below the header
BOARD_ROW   EQU 2               ; character row of the board's top
    ASSERT BOARD_ROW + 2 * @Level.HEIGHT <= 24

NONE        EQU 0xFFFF          ; no number shown yet (not valid BCD)

; The board squares under the pause menu's window (see Pause), which
; resume redraws: rows and columns of squares, first and last.
PAUSE_TOP    EQU (@Pause.TOP - BOARD_ROW) / 2
PAUSE_BOTTOM EQU (@Pause.TOP + @Pause.HEIGHT - 1 - BOARD_ROW) / 2
PAUSE_LEFT   EQU @Pause.LEFT / 2
PAUSE_RIGHT  EQU (@Pause.LEFT + @Pause.WIDTH - 1) / 2
    ASSERT @Pause.TOP >= BOARD_ROW && PAUSE_BOTTOM < @Level.HEIGHT
    ASSERT PAUSE_RIGHT < @Level.WIDTH

; Play the current level (Level.number) from the start: load it and draw
; the whole screen: the status lines, then the board, which covers the rest
; of the screen, so nothing needs clearing first. Call it with the time
; stopped (see Level.load).
start:
    PROFILE_BORDER @Color.BLACK    ; not the colour of the screen we came from
    call @Level.load

    ASSERT BOARD_ROW + 2 * @Level.HEIGHT == 24 && 2 * @Level.WIDTH == 32
    call init_status_lines      ; header and "Best" line
    ld hl,NONE                  ; pushes and time not shown yet: draw shows them
    ld (shown_pushes),hl
    ld (shown_time),hl
    call draw_board
    jr play

; Go back to playing the current level as it was left by the pause menu:
; redraw only the squares under its window.
resume:
    PROFILE_BORDER @Color.BLACK    ; not the colour of the screen we came from
    ld l,PAUSE_TOP * @Level.WIDTH + PAUSE_LEFT
    ld de,(PAUSE_BOTTOM - PAUSE_TOP + 1) << 8 | (PAUSE_RIGHT - PAUSE_LEFT + 1)
    call draw_squares
    ; fall through

play:
    call @Input.reset           ; ignore inputs from the previous screen

    ld a,1                      ; start the time
    ld (@Level.time_running),a

event_loop:
    halt
    PROFILE_BORDER @Color.BLUE     ; drawing
    call draw
    PROFILE_BORDER @Color.RED      ; processing after the draw
    jp update                   ; may switch to another screen
update_return:
    PROFILE_BORDER @Color.BLACK    ; idle until the next frame
    jr event_loop

; Set up the status lines at the top, rows above the board, cleared in
; Color.TEXT_ATTR: the header (row 0) with the level number, and the "Best"
; line (row 1). The pushes and time in the header are left to draw.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
init_status_lines:
    ASSERT BEST_ROW < BOARD_ROW
    ld bc,0 << 8 | 0            ; rows 0 to BOARD_ROW - 1, all columns
    ld de,BOARD_ROW << 8 | 32
    call @Screen.clear_cells
    ld a,@Color.TEXT_ATTR
    ld bc,0 << 8 | 0
    ld de,BOARD_ROW << 8 | 32
    call @Screen.paint_cells

    call @Header.print_labels   ; row 0: "Level", "Pushes", "Time", ':'

    ; Show the current level (Level.number_bcd).
    ld de,@Screen.bitmap + @Header.LEVEL_COLUMN ; row 0
    ld a,(@Level.number_bcd)
    call @Screen.print_digits_2

    ; Row 1: the level's best pushes and time, each under the header's
    ; and labelled "Best" under "Pushes" and "Time".
    ASSERT BEST_ROW < 8
BEST_LINE EQU @Screen.bitmap + BEST_ROW * 32 ; rows 0-7: just + 32
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

; Draw the whole board (Level.board), so it can redraw the board over
; anything (see draw_squares).
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw_board:
    ld l,0                      ; the top left square
    ld de,@Level.HEIGHT << 8 | @Level.WIDTH
    ; fall through

; Draw a rectangle of board squares (see draw_square), then the bulldozer
; on top, wherever it is: if its square isn't in the rectangle, drawing it
; again changes nothing.
; Entry: L = position of the top left square, D = height, E = width, in
; squares (at least 1 each).
; Exit: none.  Clobbers: A, BC, DE, HL.
draw_squares:
    ASSERT low @Level.board == 0
    ld h,high @Level.board      ; HL = the square in Level.board
.row:
    push de                     ; D = rows left, E = width
.square:
    push de                     ; E = squares left in the row
    call draw_square
    pop de
    inc l
    dec e
    jr nz,.square
    pop de
    ld a,l                      ; L = the next row's first square
    sub e
    add a,@Level.WIDTH
    ld l,a
    dec d
    jr nz,.row
    ; fall through

; Draw the bulldozer (Level.bulldozer), facing Level.facing, over its
; square, with its tracks in phase 0 (see Sprite.bulldozer). Leaves the
; square's attributes as they are.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw_bulldozer:
    ld a,(@Level.bulldozer)
    call square_cell            ; B, C = cell
    ASSERT @Sprite.TRACK_PHASES * 0x20 == 0x80
    ld a,(@Level.facing)        ; HL = Sprite.bulldozer + facing * 0x80
    ld l,0
    srl a
    rr l
    ld h,a
    ld de,@Sprite.bulldozer
    add hl,de
    jp @Screen.draw_tile

; Draw a square of the board in its colours, without the bulldozer (see
; draw_bulldozer):
; - a wall: Sprite.wall in Color.WALL_ATTR;
; - floor, in Color.TARGET_ATTR on a target and Color.FLOOR_ATTR otherwise:
;   a crate, else a target, else nothing;
; - outside the walls: nothing, in Color.OUTSIDE_ATTR.
; Entry: HL = square in Level.board.
; Exit: HL unchanged.  Clobbers: A, BC, DE.
draw_square:
    push hl
    ld a,l
    call square_cell            ; B, C = cell
    ld a,(hl)
    and @Level.WALL
    jr nz,.wall
    ld a,(hl)
    and @Level.FLOOR
    jr z,.outside

    ld a,(hl)                   ; D = attribute
    and @Level.TARGET
    ld d,@Color.FLOOR_ATTR      ; (ld leaves the flags)
    jr z,.attr_done
    ld d,@Color.TARGET_ATTR
.attr_done:
    ld a,(hl)                   ; HL = sprite
    and @Level.CRATE
    jr nz,.crate
    ld a,(hl)
    and @Level.TARGET
    jr z,.clear
    ld hl,@Sprite.target
    jr .draw
.crate:
    ld hl,@Sprite.crate
    jr .draw

.outside:
    ld d,@Color.OUTSIDE_ATTR
.clear:
    push bc
    push de
    call @Screen.clear_tile
    pop de
    pop bc
    jr .paint
.wall:
    ld d,@Color.WALL_ATTR
    ld hl,@Sprite.wall
.draw:
    push bc
    push de
    call @Screen.draw_tile
    pop de
    pop bc
.paint:
    ld a,d
    call @Screen.paint_tile
    pop hl
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

; Draw what changes from frame to frame: the bulldozer, in the current
; frame of its move if it is moving (see draw_move), then the level's
; pushes and time (Level.pushes, Level.time) in the header, each only if
; it has changed since it was last shown.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw:
    ld a,(@Level.frame)
    or a
    jr nz,.moving
    call draw_bulldozer         ; still: it may have turned
    jr .board_done
.moving:
    call draw_move
.board_done:

    ; show pushes
    ld hl,(@Level.pushes)
    ld de,(shown_pushes)
    or a
    sbc hl,de
    jr z,.pushes_done
    add hl,de                   ; HL = pushes again
    ld (shown_pushes),hl
    ld de,@Screen.bitmap + @Header.PUSHES_COLUMN ; row 0
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
    ld de,@Screen.bitmap + @Header.TIME_COLUMN
    jp @Screen.print_time

; Draw the squares that change in the current frame of the bulldozer's
; move (Level.frame), from Anim.tiles: the square it leaves, then either
; the square it enters or, in a push, the crate's square and the square
; the crate enters.
; Entry: moving.  Exit: none.  Clobbers: A, BC, DE, HL.
draw_move:
    ASSERT (@Anim.tiles & 0xFF) == 0 && @Anim.FRAMES == 16
    ld a,(@Level.facing)        ; D = the frame's page in Anim.tiles
    add a,a
    add a,a
    add a,a
    add a,a
    ld b,a
    ld a,(@Level.frame)
    add a,b
    add a,(@Anim.tiles >> 8) - 1
    ld d,a
    call @Level.step
    ld e,a                      ; E = step
    ld a,(@Level.bulldozer)
    ld l,a
    ld h,@Level.board >> 8      ; HL = the square it leaves

    ld c,@Anim.LEAVE_FLOOR
    call draw_move_square
    ld a,l                      ; the square ahead
    add a,e
    ld l,a
    ld a,(hl)
    and @Level.CRATE
    jr nz,.push
    ld c,@Anim.ENTER_FLOOR
    jr draw_move_square
.push:
    ld c,@Anim.PUSH
    call draw_move_square
    ld a,l                      ; the square the crate enters
    add a,e
    ld l,a
    ld c,@Anim.CRATE_FLOOR
    ; fall through

; Draw a square's tile in the current frame of a move.
; Entry: HL = square in Level.board, C = kind of tile (see Anim): if
; Anim.LEAVE_FLOOR, ENTER_FLOOR or CRATE_FLOOR, the target kind instead
; when the square is a target; D = the frame's page in Anim.tiles.
; Exit: DE, HL unchanged.  Clobbers: A, BC.
draw_move_square:
    ASSERT @Anim.LEAVE_TARGET == @Anim.LEAVE_FLOOR + 1
    ASSERT @Anim.ENTER_TARGET == @Anim.ENTER_FLOOR + 1
    ASSERT @Anim.CRATE_TARGET == @Anim.CRATE_FLOOR + 1
    ld a,c
    cp @Anim.PUSH
    jr z,.kind_done             ; the same on a target
    ld a,(hl)
    and @Level.TARGET
    jr z,.kind_done
    inc c
.kind_done:
    push de
    push hl
    ld a,c                      ; E = kind * 0x20, the tile's low byte
    rrca                        ; (kind < 8)
    rrca
    rrca
    ld e,a
    ld a,l
    call square_cell            ; B, C = cell
    ld l,e
    ld h,d
    call @Screen.draw_tile
    pop hl
    pop de
    ret

; Act on the inputs. Jumped to from event_loop, not called, so it can
; switch to another screen with nothing left on the stack.
; - Pressing fire (Input.get_pressed) pauses (Pause.start).
; - While the bulldozer moves, go to the move's next frame; after its last
;   frame, end the move (Level.end_move), and if that solves the level (no
;   crate left off a target), go to the solved screen (Solved.start).
; - When it isn't moving (or has just stopped), a direction held
;   (Input.held) turns it that way and starts a move if it can
;   (Level.move). With several held, the first of RIGHT, LEFT, DOWN, UP.
; Entry: none.
; Exit: to Pause.start, Solved.start, or update_return.
; Clobbers: A, BC, HL.
update:
    call @Input.get_pressed
    bit @Input.FIRE,a
    jp nz,@Pause.start

    ld a,(@Level.frame)
    or a
    jr z,.still
    cp @Anim.FRAMES
    jr z,.end_move
    inc a
    ld (@Level.frame),a
    jp update_return
.end_move:
    call @Level.end_move
    ld a,(@Level.remaining)
    or a
    jp z,@Solved.start
.still:
    ld a,(@Input.held)
    ASSERT @Math.RIGHT == 0 && @Math.LEFT == 1
    ASSERT @Math.DOWN == 2 && @Math.UP == 3
    and 0x0F                    ; the directions
    jp z,update_return
    ld b,-1                     ; B = the first direction held
.direction:
    inc b
    rrca
    jr nc,.direction
    ld a,b
    call @Level.move
    jp update_return

best_text:
    DB "Best"
BEST_TEXT_LEN EQU $ - best_text

shown_pushes: DW NONE           ; pushes shown in the header, or NONE
shown_time:   DW NONE           ; time shown in the header, or NONE

    ENDMODULE
