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

; Make a level the current one: set `number_bcd` and `number`, and copy its
; high scores to `best`.
; Entry: A = level number in BCD (0x00-0x99).
; Exit: none.  Clobbers: A, BC, DE, HL.
select:
    ld (number_bcd),a
    call @Math.from_bcd
    ld (number),a
    ld l,a                      ; HL = high_scores + number * HIGH_SCORE_SIZE
    ld h,0
    ASSERT @Alloc.HIGH_SCORE_SIZE == 4
    add hl,hl
    add hl,hl
    ld de,@Alloc.high_scores
    add hl,de
    ld de,best
    ld bc,@Alloc.HIGH_SCORE_SIZE
    ldir
    ret

; The current level.
number_bcd: DB 0                ; level number in BCD
number:     DB 0                ; level number in binary
; Its high scores, laid out like an entry of Alloc.high_scores.
best:
best_pushes: DW NO_SCORE
best_time:   DW NO_SCORE
    ASSERT best_pushes - best == @Alloc.HIGH_SCORE_PUSHES
    ASSERT best_time - best == @Alloc.HIGH_SCORE_TIME
    ASSERT $ - best == @Alloc.HIGH_SCORE_SIZE

    ENDMODULE
