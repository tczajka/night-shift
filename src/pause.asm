; Pause screen (design/pause.txt): a menu in a window over the play
; screen.

    MODULE Pause

; The window: a border one cell wide around the menu lines.
TOP         EQU 10              ; character row of the window's top
LEFT        EQU 10              ; character column of its left
HEIGHT      EQU 5
WIDTH       EQU 11
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
    ld bc,(TOP + 1) << 8 | (LEFT + 1)
    ld de,(HEIGHT - 2) << 8 | (WIDTH - 2)
    call @Screen.paint_cells

    call print_menu

event_loop:                     ; nothing to do yet
    halt
    jr event_loop

; Print the menu lines inside the window.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
print_menu:
    ld bc,(TOP + 1) << 8 | TEXT_COLUMN
    call @Screen.char_address
    ld hl,resume_text
    ld b,RESUME_TEXT_LEN
    call @Screen.print_string
    ld bc,(TOP + 2) << 8 | TEXT_COLUMN
    call @Screen.char_address
    ld hl,restart_text
    ld b,RESTART_TEXT_LEN
    call @Screen.print_string
    ld bc,(TOP + 3) << 8 | TEXT_COLUMN
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

    ENDMODULE
