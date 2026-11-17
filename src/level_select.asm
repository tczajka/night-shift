; Level select screen (design/level-select.txt).

    MODULE LevelSelect

NONE        EQU 0xFF            ; no level (not valid BCD)

start:
    PROFILE_BORDER @Color.BLACK    ; not the colour of the screen we came from
    ld a,@Color.TEXT_ATTR
    call @Screen.clear

    call @Header.print_labels   ; row 0: "Level", "Pushes", "Time", ':'

    call print_select_level     ; row 1: "Select level"
    call print_levels           ; rows 3-21: "00" ... "99"
    call print_solved           ; row 23: "Solved: 000"

    ld a,NONE                   ; no level shown as selected yet
    ld (shown_bcd),a
    call @Input.reset           ; ignore inputs from before the finished screen

event_loop:
    halt
    PROFILE_BORDER @Color.BLUE     ; drawing
    call draw
    PROFILE_BORDER @Color.RED      ; processing after the draw
    jp update                   ; may switch to another screen
update_return:
    PROFILE_BORDER @Color.BLACK    ; idle until the next frame
    jr event_loop

; Print "Select level" in row 1.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
print_select_level:
    ld bc,1 << 8 | 10           ; row 1, column 10
    call @Screen.char_address
    ld hl,select_level_text
    ld b,SELECT_LEVEL_TEXT_LEN
    jp @Screen.print_string

; Print the level numbers 00-99 in a grid of 10 by 10 (see level_cell),
; solved levels in green.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
print_levels:
    xor a                       ; level number in BCD
.level:
    push af
    call level_cell
    call @Screen.char_address
    pop af
    push af
    call @Screen.print_digits_2
    pop af
    push af
    call normal_attr
    ld h,a
    pop af
    push af
    call paint_level
    pop af
    add a,1                     ; next level, in BCD
    daa
    ASSERT @Levels.COUNT == 100
    jr nc,.level                ; until 99 wraps to 00
    ret

; Print the number of solved levels (Levels.solved_bcd) in row 23:
; "Solved: 000".
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
print_solved:
    ld bc,23 << 8 | 10          ; row 23, column 10
    call @Screen.char_address
    ld hl,solved_text           ; "Solved:"
    ld b,SOLVED_TEXT_LEN
    call @Screen.print_string
    inc e                       ; skip a space
    ld hl,(@Levels.solved_bcd)
    jp @Screen.print_digits_3

; Show the current level (Level.number_bcd) as selected, if it isn't
; already: give the previously selected one back its normal colour, give
; the current one Color.SELECTED_ATTR, and print its number and best
; scores in the header.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw:
    ld a,(@Level.number_bcd)
    ld hl,shown_bcd
    cp (hl)
    ret z
    ld a,(hl)
    cp NONE
    jr z,.select
    call normal_attr
    ld h,a
    ld a,(shown_bcd)
    call paint_level
.select:
    ld a,(@Level.number_bcd)
    ld (shown_bcd),a
    ld h,@Color.SELECTED_ATTR
    call paint_level

    ; Header: the level's number and its best pushes and time.
    ld de,@Screen.bitmap + @Header.LEVEL_COLUMN ; row 0
    ld a,(@Level.number_bcd)
    call @Screen.print_digits_2
    ld de,@Screen.bitmap + @Header.PUSHES_COLUMN
    ld hl,(@Level.best_pushes)
    call @Screen.print_digits_4
    ld de,@Screen.bitmap + @Header.TIME_COLUMN
    ld hl,(@Level.best_time)
    jp @Screen.print_time

; Act on the inputs pressed (Input.get_pressed). Jumped to from event_loop,
; not called, so it can switch to another screen with nothing left on the
; stack.
; Fire plays the current level (Play.start). Otherwise, move the current
; level with the direction inputs: in BCD, +1 / -1 for right / left and
; +0x10 / -0x10 for down / up. Moving off an edge of the grid wraps around
; to the opposite edge.
; Entry: none.
; Exit: to Play.start, or to update_return.  Clobbers: A, BC, D, HL.
update:
    call @Input.get_pressed
    bit @Input.FIRE,a
    jp nz,@Play.start           ; play the current level

    ld b,a                      ; B = pressed inputs
    ld a,(@Level.number_bcd)
    ld c,a                      ; C = current level, BCD

    bit @Math.RIGHT,b
    jr z,.right_done
    inc a
    ld d,a
    and 0x0F
    cp 10
    ld a,d
    jr nz,.right_done
    sub 10                      ; units 9 -> 0
.right_done:
    bit @Math.LEFT,b
    jr z,.left_done
    ld d,a
    and 0x0F
    ld a,d
    jr nz,.not_leftmost
    add a,10                    ; units 0 -> 9, after the dec
.not_leftmost:
    dec a
.left_done:
    bit @Math.DOWN,b
    jr z,.down_done
    add a,0x10
    cp 0xA0
    jr c,.down_done
    sub 0xA0                    ; tens 9 -> 0
.down_done:
    bit @Math.UP,b
    jr z,.up_done
    sub 0x10
    jr nc,.up_done
    add a,0xA0                  ; tens 0 -> 9
.up_done:

    cp c
    jp z,update_return          ; unchanged
    call @Level.select
    jp update_return

; Character cell of a level's number in the grid: level tens:units is at
; row 3 + 2 * tens, column 1 + 3 * units.
; Entry: A = level number in BCD (0x00-0x99).
; Exit: B = row, C = column of the first digit.  Clobbers: A.
level_cell:
    ld c,a                      ; B = 3 + 2 * tens
    and 0xF0                    ; tens * 16
    rrca
    rrca
    rrca                        ; tens * 2
    add a,3
    ld b,a
    ld a,c                      ; C = 1 + 3 * units
    and 0x0F
    ld c,a
    add a,a
    add a,c
    inc a
    ld c,a
    ret

; The attribute of a level's number when it isn't selected:
; Color.SOLVED_ATTR if the level is solved, Color.TEXT_ATTR if not.
; Entry: A = level number in BCD.  Exit: A = attribute.  Clobbers: BC, HL.
normal_attr:
    call @Math.from_bcd
    call @Levels.is_solved
    ld a,@Color.TEXT_ATTR
    ret z
    ld a,@Color.SOLVED_ATTR
    ret

; Set the attribute of both cells of a level's number.
; Entry: A = level number in BCD, H = attribute.
; Exit: none.  Clobbers: A, BC, DE.
paint_level:
    call level_cell
    call @Screen.attr_address
    ld a,h
    ld (de),a
    inc e
    ld (de),a
    ret

select_level_text:
    DB "Select level"
SELECT_LEVEL_TEXT_LEN EQU $ - select_level_text
solved_text:
    DB "Solved:"
SOLVED_TEXT_LEN EQU $ - solved_text

shown_bcd:  DB NONE             ; level shown as selected, in BCD, or NONE

    ENDMODULE
