; Header, row 0 of the level select and level screens:
; "Level 00  Pushes 0000 Time 00:00".

    MODULE Header

; Print the header labels. The numbers go in the gaps; within a row, moving
; right just adds to E.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
print_labels:
    ld hl,level_text
    ld a,LEVEL_TEXT_LEN
    ld bc,0 << 8 | 0            ; row 0, column 0
    call @Screen.print_string
    ld a,e
    add a,5                     ; to column 10
    ld e,a
    ld hl,pushes_text
    ld b,PUSHES_TEXT_LEN
    call @Screen.print_string_addr
    ld a,e
    add a,6                     ; to column 22
    ld e,a
    ld hl,time_text
    ld b,TIME_TEXT_LEN
    call @Screen.print_string_addr
    ld a,e
    add a,3                     ; to column 29
    ld e,a
    ld a,':'
    jp @Screen.print_char_addr

level_text:
    DB "Level"
LEVEL_TEXT_LEN EQU $ - level_text
pushes_text:
    DB "Pushes"
PUSHES_TEXT_LEN EQU $ - pushes_text
time_text:
    DB "Time"
TIME_TEXT_LEN EQU $ - time_text

    ENDMODULE
