; Levels and their high scores (see Alloc.high_scores).

    MODULE Level

COUNT       EQU 100             ; levels are numbered 00-99
NO_SCORE    EQU 0xFFFF          ; pushes and time of a level not solved yet

; Mark every level as not solved yet: set all high scores to NO_SCORE.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
init:
    ld hl,@Alloc.high_scores
    ld bc,@Alloc.high_scores_end - @Alloc.high_scores
    ASSERT NO_SCORE == 0xFFFF   ; both bytes the same
    ld a,NO_SCORE & 0xFF
    jp @Memory.fill

    ENDMODULE
