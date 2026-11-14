; Screen drawing: clearing and text.
;
; The bitmap is not linear: for character row r (0-23), column c (0-31)
; and pixel line y (0-7) of the cell, the address is
;   0x4000 | (r & 0x18) << 8 | y << 8 | (r & 7) << 5 | c
; so the 8 lines of a character cell are 256 bytes apart.

    MODULE Screen

FONT        EQU 0x3C00          ; ROM font, 8 bytes per character, indexed from
                                ; character 0; only 32-127 exist (from 0x3D00)

; Colours, for attributes: ink | paper << 3 | BRIGHT.
BLACK       EQU 0
BLUE        EQU 1
RED         EQU 2
MAGENTA     EQU 3
GREEN       EQU 4
CYAN        EQU 5
YELLOW      EQU 6
WHITE       EQU 7
BRIGHT      EQU 0x40

; Set every attribute to A, then clear the bitmap. The attributes go first
; and take under a third of a frame, so the colours change almost at once;
; clearing the bitmap then takes about two frames.
; Entry: A = attribute.  Exit: none.  Clobbers: A, BC, DE, HL.
clear:
    ld hl,@Alloc.screen_attrs
    ld bc,@Alloc.screen_attrs_end - @Alloc.screen_attrs
    call @Memory.fill
    ld hl,@Alloc.screen_bitmap
    ld bc,@Alloc.screen_bitmap_end - @Alloc.screen_bitmap
    xor a
    jp @Memory.fill

; Draw a time in BCD as minutes and seconds, skipping the cell between them
; (where the ':' is already drawn). A digit 0xF is drawn as '-' (see
; print_digit). Leaves attributes unchanged.
; Entry: HL = time in BCD, 0xMMSS (minutes in H, seconds in L), DE = address
; of the first digit's cell (see char_address).
; Exit: DE = address of the cell after the seconds (see print_char).
; Clobbers: A, B, HL.
print_time:
    ld a,l                      ; seconds, for later
    push af
    ld a,h                      ; minutes
    call print_digits_2
    inc e                       ; skip the ':'
    pop af
    jr print_digits_2

; Draw a 4-digit binary coded decimal number from the ROM font; a digit
; 0xF is drawn as '-' (see print_digit). Leaves attributes unchanged.
; Entry: HL = number in BCD (0x0000-0x9999), DE = address of the first
; digit's cell (see char_address).
; Exit: DE = address of the cell after the number (see print_char).
; Clobbers: A, B, HL.
print_digits_4:
    ld a,l                      ; low 2 digits, for later
    push af
    ld a,h                      ; high 2 digits
    call print_digits_2
    pop af
    jr print_digits_2

; Draw a 3-digit binary coded decimal number from the ROM font; a digit
; 0xF is drawn as '-' (see print_digit). Leaves attributes unchanged.
; Entry: HL = number in BCD (0x000-0x999; the top 4 bits are ignored),
; DE = address of the first digit's cell (see char_address).
; Exit: DE = address of the cell after the number (see print_char).
; Clobbers: A, B, HL.
print_digits_3:
    ld a,l                      ; low 2 digits, for later
    push af
    ld a,h                      ; high digit
    call print_digit
    pop af
    ; fall through

; Draw a 2-digit binary coded decimal number from the ROM font; a digit
; 0xF is drawn as '-' (see print_digit). Leaves attributes unchanged.
; Entry: A = number in BCD (0x00-0x99), DE = address of the first digit's
; cell (see char_address).
; Exit: DE = address of the cell after the number (see print_char).
; Clobbers: A, B, HL.
print_digits_2:
    push af
    rrca                        ; high digit
    rrca
    rrca
    rrca
    call print_digit
    pop af                      ; low digit
    ; fall through

; Draw a decimal digit from the ROM font, or '-' for 0xF, so that
; Level.NO_SCORE shows as dashes. Leaves the attribute unchanged.
; Entry: A = digit (0-9, or 0xF) in the low 4 bits; the high 4 bits are
; ignored. DE = address of the cell (see char_address).
; Exit: DE = address of the next cell (see print_char).
; Clobbers: A, B, HL.
print_digit:
    and 0x0F
    add a,'0'
    cp '0' + 0x0F
    jr nz,print_char
    ld a,'-'
    ; fall through

; Draw a character from the ROM font at a bitmap address. Leaves the cell's
; attribute unchanged.
; Entry: A = character (32-127), DE = address of the cell's top pixel line
; (see char_address).
; Exit: DE = address of the next cell to the right.
; Clobbers: A, B, HL.
print_char:
    ld l,a                      ; HL = FONT + A * 8
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    ASSERT (FONT & 0x3FF) == 0  ; A * 8 < 0x400, so OR adds FONT
    ld a,h
    or FONT >> 8
    ld h,a

    ld b,8
.line:
    ld a,(hl)
    ld (de),a
    inc hl
    inc d                       ; next pixel line of the cell
    djnz .line

    ld a,d                      ; back to the top line
    sub 8
    ld d,a
    inc e                       ; next cell
    ret

; Draw a string from the ROM font, left to right from a bitmap address.
; Leaves attributes unchanged.
; Entry: HL = string, B = length (0-255), DE = address of the first cell's
; top pixel line (see char_address).
; Exit: DE = address of the cell after the string (see print_char).
; Clobbers: A, B, HL.
print_string:
    ld a,b
    or a
    ret z
.char:
    ld a,(hl)
    push hl
    push bc
    call print_char
    pop bc
    pop hl
    inc hl
    djnz .char
    ret

; Bitmap address of the top pixel line of a character cell. The cell's other
; 7 lines follow at D + 1 ... D + 7, with E unchanged.
; Entry: B = row (0-23), C = column (0-31).
; Exit: DE = address.  Clobbers: A.
char_address:
    ld a,b                      ; D = 0x40 | (row & 0x18)
    and 0x18
    or @Alloc.screen_bitmap >> 8
    ld d,a
    ld a,b                      ; E = (row & 7) << 5 | column
    and 7
    rrca
    rrca
    rrca
    or c
    ld e,a
    ret

; Attribute address of a character cell. Attributes are linear: the address
; is screen_attrs + row * 32 + column.
; Entry: B = row (0-23), C = column (0-31).
; Exit: DE = address.  Clobbers: A.
attr_address:
    ld a,b                      ; A = (row & 7) << 5 | row >> 3
    rrca
    rrca
    rrca
    ld d,a
    and 0xE0                    ; E = (row & 7) << 5 | column
    or c
    ld e,a
    ld a,d                      ; D = high byte of screen_attrs + row >> 3
    and 3
    ASSERT (@Alloc.screen_attrs & 0x3FF) == 0   ; so OR adds row >> 3
    or @Alloc.screen_attrs >> 8
    ld d,a
    ret

    ENDMODULE
