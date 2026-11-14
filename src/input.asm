; Player input: keys Q/A/O/P and Space, plus a Kempston joystick if one is
; connected.
;
; Inputs use the Kempston bit layout, 1 = pressed: bit 0 right, 1 left,
; 2 down, 3 up, 4 fire. `scan` runs from the frame interrupt and updates
; `held` (inputs down now) and `pressed` (inputs that went down since the
; last `get_pressed`, so no press is lost if the game skips a frame).

    MODULE Input

; Bit numbers, for BIT/SET/RES.
RIGHT   EQU 0
LEFT    EQU 1
DOWN    EQU 2
UP      EQU 3
FIRE    EQU 4
ALL     EQU 0x1F                ; mask of all five inputs

KEMPSTON_PORT  EQU 0x1F

; Read the keys and the Kempston joystick; update `held` and add newly
; pressed inputs to `pressed`. Called from the frame interrupt handler.
;
; Keyboard half-rows read 0 for a pressed key. P and O are bits 0 and 1 of
; half-row 0xDFFE, the same bits as right and left.
;
; The Kempston port is read even with no interface: then the bus is idle
; and reads 0xFF, which is ignored. A Kempston returns bits 6-7 as 0 (bit 5
; may be a second fire button). This relies on running before the ULA
; starts fetching the picture: during the picture an idle bus returns
; screen bytes, which can pass the check and look like random presses.
;
; Entry: none.  Exit: none.  Clobbers: A, BC, flags.
scan:
    ld a,0xDF                   ; half-row P O I U Y
    in a,(0xFE)
    cpl
    ASSERT RIGHT == 0 && LEFT == 1  ; P and O are already in place
    and (1 << RIGHT) | (1 << LEFT)
    ld c,a                      ; C = inputs held, 1 = pressed

    ; A, Q and Space are bit 0 of their half-rows: invert, rotate into
    ; place, mask and merge.

    ld a,0xFD                   ; half-row A S D F G
    in a,(0xFE)
    cpl
    DUP DOWN                    ; bit 0 -> bit DOWN
    rlca
    EDUP
    and 1 << DOWN
    or c
    ld c,a

    ld a,0xFB                   ; half-row Q W E R T
    in a,(0xFE)
    cpl
    DUP UP                      ; bit 0 -> bit UP
    rlca
    EDUP
    and 1 << UP
    or c
    ld c,a

    ld a,0x7F                   ; half-row Space Sym M N B
    in a,(0xFE)
    cpl
    DUP FIRE                    ; bit 0 -> bit FIRE
    rlca
    EDUP
    and 1 << FIRE
    or c
    ld c,a

    in a,(KEMPSTON_PORT)
    cp 0x40                     ; bits 6-7 not both 0: no Kempston
    jr nc,.no_kempston
    and ALL
    or c
    ld c,a
.no_kempston:
    ld a,(held)                 ; inputs held on the previous scan
    cpl
    and c                       ; held now, not before
    ld b,a
    ld a,(pressed)
    or b
    ld (pressed),a
    ld a,c
    ld (held),a
    ret

; Forget all inputs: treat every input as held, so one down now counts as
; pressed only after it is released and pressed again, and clear `pressed`.
; Call with interrupts disabled, before enabling them for a new screen.
; Entry: none.  Exit: none.  Clobbers: A.
reset:
    ld a,ALL
    ld (held),a
    xor a
    ld (pressed),a
    ret

; Return the inputs pressed since the previous call, and clear `pressed`.
;
; If this is called exactly between frames, a key press may be lost.
;
; Entry: none.  Exit: A = pressed inputs.  Clobbers: HL.
get_pressed:
    ld hl,pressed
    ld a,(hl)
    ; If the frame interrupt fires here, `scan` adds new presses to
    ; `pressed`, and the next instruction clears them unseen: they are lost.
    ld (hl),0
    ret

held:       DB 0                ; inputs held now (see reset)
pressed:    DB 0                ; inputs pressed since the last get_pressed

    ENDMODULE
