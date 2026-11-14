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
    call @Memory.fill

    ; TEMPORARY: level 13 solved in 2718 pushes, 31:41.
.TEST_SCORE EQU @Alloc.high_scores + 13 * @Alloc.HIGH_SCORE_SIZE
    ld hl,0x2718
    ld (.TEST_SCORE + @Alloc.HIGH_SCORE_PUSHES),hl
    ld hl,0x3141
    ld (.TEST_SCORE + @Alloc.HIGH_SCORE_TIME),hl
    ld hl,0x0001
    ld (solved_bcd),hl
    ret

; Make a level the current one: set `number_bcd` and `number`, and copy its
; high scores to `best`.
; Entry: A = level number in BCD (0x00-0x99).
; Exit: none.  Clobbers: A, BC, DE, HL.
select:
    ld (number_bcd),a
    call @Math.from_bcd
    ld (number),a
    call high_score_address
    ld de,best
    ld bc,@Alloc.HIGH_SCORE_SIZE
    ldir
    ret

; Whether a level is solved, i.e. its high scores aren't NO_SCORE.
; Entry: A = level number in binary (0-99).
; Exit: Z if not solved, NZ if solved.  Clobbers: A, HL.
is_solved:
    call high_score_address
    ASSERT @Alloc.HIGH_SCORE_PUSHES == 0
    ld a,(hl)                   ; low byte of best pushes
    ASSERT (NO_SCORE & 0xFF) == 0xFF    ; no BCD byte is 0xFF
    inc a
    ret

; Address of a level's entry in Alloc.high_scores.
; Entry: A = level number in binary (0-99).
; Exit: HL = address.  Clobbers: A.
high_score_address:
    ld l,a                      ; HL = number * HIGH_SCORE_SIZE
    ld h,0
    ASSERT @Alloc.HIGH_SCORE_SIZE == 4
    add hl,hl
    add hl,hl
    ld a,h                      ; + high_scores
    ASSERT (@Alloc.high_scores & 0xFF) == 0
    add a,@Alloc.high_scores >> 8
    ld h,a
    ret

solved_bcd: DW 0                ; number of solved levels in BCD (0x0000-0x0100)

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
