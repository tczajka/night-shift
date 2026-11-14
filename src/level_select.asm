; Level select screen (design/level-select.txt).

    MODULE LevelSelect

ATTR        EQU @Screen.WHITE | @Screen.BLACK << 3 | @Screen.BRIGHT
SOLVED_ATTR EQU @Screen.GREEN | @Screen.BLACK << 3 | @Screen.BRIGHT

start:
    ld a,ATTR
    call @Screen.clear

    call @Header.print_labels   ; row 0: "Level", "Pushes", "Time", ':'

    ; "Select level"
    ld bc,1 << 8 | 10           ; row 1, column 10
    call @Screen.char_address
    ld hl,select_level_text
    ld b,SELECT_LEVEL_TEXT_LEN
    call @Screen.print_string

    call print_levels           ; rows 3-21: "00" ... "99"

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

; Print the level numbers 00-99 in a grid of 10 by 10 (see level_cell),
; solved levels in green.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL, IX.
print_levels:
    ld ix,@Alloc.high_scores
    xor a                       ; level number in BCD
.level:
    push af
    call level_cell
    call @Screen.char_address
    pop af
    push af
    push bc
    call @Screen.print_digits_2
    pop bc

    ld a,(ix + @Alloc.HIGH_SCORE_PUSHES)
    ASSERT (@Level.NO_SCORE & 0xFF) == 0xFF ; no BCD byte is 0xFF
    inc a
    jr z,.next                  ; not solved
    call @Screen.attr_address
    ld a,SOLVED_ATTR
    ld (de),a                   ; both digits' cells
    inc e
    ld (de),a
.next:
    ld de,@Alloc.HIGH_SCORE_SIZE
    add ix,de
    pop af
    add a,1                     ; next level, in BCD
    daa
    ASSERT @Level.COUNT == 100
    jr nc,.level                ; until 99 wraps to 00
    ret

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

select_level_text:
    DB "Select level"
SELECT_LEVEL_TEXT_LEN EQU $ - select_level_text
solved_text:
    DB "Solved:"
SOLVED_TEXT_LEN EQU $ - solved_text

    ENDMODULE
