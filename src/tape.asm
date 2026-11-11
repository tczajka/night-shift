; Tape image: a BASIC loader followed by the machine-code block.
;
; The loader is a single line:
;
;   10 CLEAR VAL "32767": LOAD "" CODE : RANDOMIZE USR VAL "32768"
;
; Numbers are written as VAL "..." so they are stored only as text (no
; hidden 5-byte binary form). The ASSERTs keep that text in step with the
; real addresses: change both together.

    ASSERT code_start == 32768  ; LOAD "" CODE loads here; CLEAR just below
    ASSERT start == 32768       ; RANDOMIZE USR target

    MODULE Tape

; BASIC tokens
T_CODE      EQU 0xAF
T_VAL       EQU 0xB0
T_USR       EQU 0xC0
T_LOAD      EQU 0xEF
T_RANDOMIZE EQU 0xF9
T_CLEAR     EQU 0xFD
T_ENTER     EQU 0x0D

; The BASIC bytes only need to exist in sjasmplus's memory image so SAVETAP
; can write them. They are placed at PROG, where BASIC programs normally
; live, which is outside the saved CODE block.
    ORG 0x5CCB

basic:
    DB 0, 10                    ; line number 10 (big-endian)
    DW .line_end - .line        ; length of the rest of the line
.line:
    DB T_CLEAR, T_VAL, '"32767"', ':'
    DB T_LOAD, '""', T_CODE, ':'
    DB T_RANDOMIZE, T_USR, T_VAL, '"32768"'
    DB T_ENTER
.line_end:
basic_end:

    EMPTYTAP "nightshift.tap"
    SAVETAP "nightshift.tap", BASIC, "NightShift", basic, basic_end - basic, 10
    SAVETAP "nightshift.tap", CODE, "NightShift", @code_start, @code_end - @code_start

    ENDMODULE
