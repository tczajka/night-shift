; Tape image: a BASIC loader, the loading screen, then the machine-code block.
;
; The loader is a single line:
;
;   10 BORDER VAL "0": PAPER VAL "0": INK VAL "7": CLEAR VAL "<code - 1>":
;      POKE VAL "23739",VAL "111": LOAD "" SCREEN$ : LOAD "" CODE :
;      RANDOMIZE USR VAL "<start>"
;
; - BORDER/PAPER/INK, then CLEAR (which also clears the screen): the screen
;   is black and the picture's pixels appear in white as they load, until
;   its colours arrive at the end of the block.
; - POKE 23739,111 sets the output routine of channel S (the main screen) to
;   0x096F, a RET in the ROM. That silences the "Bytes: ..." messages the ROM
;   prints when it finds each header, which would otherwise overwrite the
;   bottom of the loading screen. Error reports go to channel K and still
;   appear.
;
; Numbers are written as VAL "..." so they are stored only as text (no
; hidden 5-byte binary form). The addresses are generated: CLEAR just
; below `code`, where LOAD "" CODE loads the code, and USR at `Start.start`,
; which moves with the size of the level data in front of it.

    MODULE Tape

; BASIC tokens
T_SCREEN    EQU 0xAA            ; SCREEN$
T_CODE      EQU 0xAF
T_VAL       EQU 0xB0
T_USR       EQU 0xC0
T_INK       EQU 0xD9
T_PAPER     EQU 0xDA
T_BORDER    EQU 0xE7
T_LOAD      EQU 0xEF
T_POKE      EQU 0xF4
T_RANDOMIZE EQU 0xF9
T_CLEAR     EQU 0xFD
T_ENTER     EQU 0x0D

; A number as 5 decimal digits in quotes, the text after VAL.
    MACRO DECIMAL_5 value
    ASSERT (value) >= 10000 && (value) <= 65535
    DB '"'
    DB '0' + (value) / 10000 % 10
    DB '0' + (value) / 1000 % 10
    DB '0' + (value) / 100 % 10
    DB '0' + (value) / 10 % 10
    DB '0' + (value) % 10
    DB '"'
    ENDM

; The BASIC bytes only need to exist in sjasmplus's memory image so SAVETAP
; can write them. They are placed at PROG, where BASIC programs normally
; live, which is outside the saved blocks.
    ORG 0x5CCB

basic:
    DB 0, 10                    ; line number 10 (big-endian)
    DW .line_end - .line        ; length of the rest of the line
.line:
    DB T_BORDER, T_VAL, '"0"', ':'
    DB T_PAPER, T_VAL, '"0"', ':'
    DB T_INK, T_VAL, '"7"', ':'
    DB T_CLEAR, T_VAL
    DECIMAL_5 @code - 1
    DB ':'
    DB T_POKE, T_VAL, '"23739"', ',', T_VAL, '"111"', ':'
    DB T_LOAD, '""', T_SCREEN, ':'
    DB T_LOAD, '""', T_CODE, ':'
    DB T_RANDOMIZE, T_USR, T_VAL
    DECIMAL_5 @Start.start
    DB T_ENTER
.line_end:
basic_end:
    ASSERT basic_end <= @code

; Loading screen: bitmap and attributes, loaded straight into screen memory
; by LOAD "" SCREEN$.
    ORG @Screen.bitmap
screen:
    INCBIN "../images/load.scr"
screen_end:
    ASSERT screen_end - screen == @Screen.attrs_end - @Screen.bitmap

    EMPTYTAP "nightshift.tap"
    SAVETAP "nightshift.tap", BASIC, "NightShift", basic, basic_end - basic, 10
    SAVETAP "nightshift.tap", CODE, "Screen", screen, screen_end - screen
    SAVETAP "nightshift.tap", CODE, "NightShift", @code, @code_end - @code

    ENDMODULE
