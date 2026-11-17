; Pause screen (design/pause.txt): a menu in a window over the play
; screen.

    MODULE Pause

; Menu items, numbered from the top line down.
RESUME      EQU 0
RESTART     EQU 1
QUIT        EQU 2
ITEMS       EQU 3               ; number of items

NONE        EQU 0xFF            ; no item

; The window: a border one cell wide around the menu lines.
TOP         EQU 10              ; character row of the window's top
LEFT        EQU 10              ; character column of its left
HEIGHT      EQU ITEMS + 2
WIDTH       EQU 11
FIRST_ROW   EQU TOP + 1         ; the first menu line
TEXT_COLUMN EQU LEFT + 2        ; the menu lines' text
    ASSERT TOP + HEIGHT <= 24 && LEFT + WIDTH <= 32

start:
    ; The window: clear it, give it the border's colour, then the text's
    ; inside the border.
    ld bc,TOP << 8 | LEFT
    ld de,HEIGHT << 8 | WIDTH
    call @Screen.clear_cells
    ld a,@Color.MENU_BORDER_ATTR
    ld bc,TOP << 8 | LEFT
    ld de,HEIGHT << 8 | WIDTH
    call @Screen.paint_cells
    ld a,@Color.TEXT_ATTR
    ld bc,FIRST_ROW << 8 | (LEFT + 1)
    ld de,(HEIGHT - 2) << 8 | (WIDTH - 2)
    call @Screen.paint_cells

    call print_menu

    xor a                       ; start on the first menu item
    ld (selected),a
    ld a,NONE                   ; no item shown as selected yet
    ld (shown),a

event_loop:
    halt
    PROFILE_BORDER @Color.BLUE     ; drawing
    call draw
    PROFILE_BORDER @Color.RED      ; processing after the draw
    jp update                   ; may switch to another screen
update_return:
    PROFILE_BORDER @Color.BLACK    ; idle until the next frame
    jr event_loop

; Show the selected item as selected, if it isn't already: give the
; previously selected one back Color.TEXT_ATTR and the selected one
; Color.SELECTED_ATTR.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
draw:
    ld a,(selected)
    ld hl,shown
    cp (hl)
    ret z
    ld a,(hl)
    cp NONE
    jr z,.select
    ld h,@Color.TEXT_ATTR
    call paint_item
.select:
    ld a,(selected)
    ld (shown),a
    ld h,@Color.SELECTED_ATTR
    ; fall through

; Set the attribute of a menu line, inside the border.
; Entry: A = item, H = attribute.
; Exit: none.  Clobbers: A, BC, DE, HL.
paint_item:
    add a,FIRST_ROW
    ld b,a
    ld c,LEFT + 1
    ld de,1 << 8 | (WIDTH - 2)
    ld a,h
    jp @Screen.paint_cells

; Act on the inputs pressed (Input.get_pressed): up and down move the
; cursor, stopping at the first and last items. Jumped to from event_loop,
; not called, so it can switch to another screen with nothing left on the
; stack.
; Entry: none.
; Exit: to update_return.  Clobbers: A, B, HL.
update:
    call @Input.get_pressed
    ld b,a                      ; B = pressed inputs
    ld a,(selected)

    bit @Math.UP,b
    jr z,.up_done
    or a
    jr z,.up_done               ; already on the first item
    dec a
.up_done:
    bit @Math.DOWN,b
    jr z,.down_done
    cp ITEMS - 1
    jr z,.down_done             ; already on the last item
    inc a
.down_done:

    ld (selected),a
    jr update_return

; Print the menu lines inside the window.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
print_menu:
    ld bc,(FIRST_ROW + RESUME) << 8 | TEXT_COLUMN
    call @Screen.char_address
    ld hl,resume_text
    ld b,RESUME_TEXT_LEN
    call @Screen.print_string
    ld bc,(FIRST_ROW + RESTART) << 8 | TEXT_COLUMN
    call @Screen.char_address
    ld hl,restart_text
    ld b,RESTART_TEXT_LEN
    call @Screen.print_string
    ld bc,(FIRST_ROW + QUIT) << 8 | TEXT_COLUMN
    call @Screen.char_address
    ld hl,quit_text
    ld b,QUIT_TEXT_LEN
    jp @Screen.print_string

resume_text:
    DB "Resume"
RESUME_TEXT_LEN EQU $ - resume_text
restart_text:
    DB "Restart"
RESTART_TEXT_LEN EQU $ - restart_text
quit_text:
    DB "Quit"
QUIT_TEXT_LEN EQU $ - quit_text
    ASSERT TEXT_COLUMN + RESTART_TEXT_LEN < LEFT + WIDTH - 1    ; fits

@code_save DEFL $
    ORG @uninit_save

selected:   DS 1                ; the item under the cursor
shown:      DS 1                ; the item shown as selected, or NONE

@uninit_save DEFL $
    ORG @code_save

    ENDMODULE
