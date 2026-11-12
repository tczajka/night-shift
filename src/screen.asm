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
; Entry: A = attribute.  Exit: none.  Clobbers: BC, DE, HL.
clear:
    ld hl,@Memory.screen_attrs
    ld de,@Memory.screen_attrs + 1
    ld bc,@Memory.screen_attrs_end - @Memory.screen_attrs - 1
    ld (hl),a
    ldir
    ld hl,@Memory.screen_bitmap
    ld de,@Memory.screen_bitmap + 1
    ld bc,@Memory.screen_bitmap_end - @Memory.screen_bitmap - 1
    ld (hl),0
    ldir
    ret

; Draw a character from the ROM font in a character cell. Leaves the cell's
; attribute unchanged.
; Entry: A = character (32-127), B = row (0-23), C = column (0-31).
; Exit: none.  Clobbers: A, B, DE, HL.
print_char:
    ld l,a                      ; HL = FONT + A * 8
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,FONT
    add hl,de
    call char_address           ; DE = screen address

    ld b,8
.line:
    ld a,(hl)
    ld (de),a
    inc hl
    inc d                       ; next pixel line of the cell
    djnz .line
    ret

; Bitmap address of the top pixel line of a character cell. The cell's other
; 7 lines follow at D + 1 ... D + 7, with E unchanged.
; Entry: B = row (0-23), C = column (0-31).
; Exit: DE = address.  Clobbers: A.
char_address:
    ld a,b                      ; D = 0x40 | (row & 0x18)
    and 0x18
    or @Memory.screen_bitmap >> 8
    ld d,a
    ld a,b                      ; E = (row & 7) << 5 | column
    and 7
    rrca
    rrca
    rrca
    or c
    ld e,a
    ret

    ENDMODULE
