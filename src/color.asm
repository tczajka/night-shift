; Colours and attributes. Constants only, no code.

    MODULE Color

; Colours, for attributes and the border (port 0xFE).
BLACK       EQU 0
BLUE        EQU 1
RED         EQU 2
MAGENTA     EQU 3
GREEN       EQU 4
CYAN        EQU 5
YELLOW      EQU 6
WHITE       EQU 7

; Attributes: ink | paper << 3 | BRIGHT.
BRIGHT      EQU 0x40

TEXT_ATTR     EQU WHITE | BLACK << 3 | BRIGHT   ; text, and the screen behind it
SOLVED_ATTR   EQU GREEN | BLACK << 3 | BRIGHT   ; a solved level on level select
SELECTED_ATTR EQU MAGENTA | BLACK << 3 | BRIGHT ; selected level or menu item
WALL_ATTR     EQU WHITE | RED << 3              ; walls: white on red
FLOOR_ATTR    EQU YELLOW | BLUE << 3 | BRIGHT   ; floor: bulldozer and crates
TARGET_ATTR   EQU GREEN | BLUE << 3 | BRIGHT    ; floor with a target
OUTSIDE_ATTR  EQU BLACK | BLACK << 3            ; outside the walls: black
MENU_BORDER_ATTR EQU BLACK | WHITE << 3         ; the pause menu's border

    ENDMODULE
