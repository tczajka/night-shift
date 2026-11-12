; Tape image: a BASIC loader, the loading screen, then the machine-code block.
;
; The loader is a single line:
;
;   10 BORDER VAL "0": PAPER VAL "0": INK VAL "7": CLEAR VAL "32767":
;      POKE VAL "23739",VAL "111": LOAD "" SCREEN$ : LOAD "" CODE :
;      RANDOMIZE USR VAL "32768"
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
; hidden 5-byte binary form). The ASSERTs keep that text in step with the
; real addresses: change both together.

    ASSERT code_start == 32768  ; LOAD "" CODE loads here; CLEAR just below
    ASSERT start == 32768       ; RANDOMIZE USR target

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
    DB T_CLEAR, T_VAL, '"32767"', ':'
    DB T_POKE, T_VAL, '"23739"', ',', T_VAL, '"111"', ':'
    DB T_LOAD, '""', T_SCREEN, ':'
    DB T_LOAD, '""', T_CODE, ':'
    DB T_RANDOMIZE, T_USR, T_VAL, '"32768"'
    DB T_ENTER
.line_end:
basic_end:

; Loading screen: bitmap and attributes, loaded straight into screen memory
; by LOAD "" SCREEN$.
    ORG @Alloc.screen_bitmap
screen:
    INCBIN "../images/load.scr"
screen_end:
    ASSERT screen_end - screen == @Alloc.screen_attrs_end - @Alloc.screen_bitmap

    EMPTYTAP "nightshift.tap"
    SAVETAP "nightshift.tap", BASIC, "NightShift", basic, basic_end - basic, 10
    SAVETAP "nightshift.tap", CODE, "Screen", screen, screen_end - screen
    SAVETAP "nightshift.tap", CODE, "NightShift", @code_start, @code_end - @code_start

    ENDMODULE
