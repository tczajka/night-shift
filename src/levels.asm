; The levels: the level data and the levels' high scores.

    MODULE Levels

COUNT       EQU 100             ; levels are numbered 00-99
NO_SCORE    EQU 0xFFFF          ; pushes and time of a level not solved yet

; The level data, built by tools/levels.py (design/level-format.md): an
; index of COUNT offsets from `data`, then the levels. On a page boundary,
; so the index is within one page and an offset just adds to the high byte
; (see address). Included first, at `code`, so the ALIGN adds nothing.
    ALIGN 0x100
data:
    INCBIN "../build/levels.bin"
data_end:

; Mark every level as not solved yet: set all high scores to NO_SCORE.
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
init:
    ld hl,high_scores
    ld bc,high_scores_end - high_scores
    ASSERT NO_SCORE == 0xFFFF   ; both bytes the same
    ld a,NO_SCORE & 0xFF
    jp @Memory.fill

; Address of a level's data (design/level-format.md).
; Entry: A = level number in binary (0-99).
; Exit: HL = address.  Clobbers: A, E.
address:
    add a,a                     ; HL = the level's index entry
    ld l,a
    ASSERT (data & 0xFF) == 0
    ASSERT 2 * COUNT <= 0x100   ; the index is within the page
    ld h,data >> 8
    ld e,(hl)                   ; HL = data + the level's offset
    inc l
    ld a,(hl)
    add a,data >> 8
    ld h,a
    ld l,e
    ret

; Whether a level is solved, i.e. its high scores aren't NO_SCORE.
; Entry: A = level number in binary (0-99).
; Exit: Z if not solved, NZ if solved.  Clobbers: A, HL.
is_solved:
    call high_score_address
    ld a,(hl)                   ; low byte of best pushes
    ASSERT (NO_SCORE & 0xFF) == 0xFF    ; no BCD byte is 0xFF
    inc a
    ret

; Address of a level's entry in high_scores.
; Entry: A = level number in binary (0-99).
; Exit: HL = address.  Clobbers: A.
high_score_address:
    ld l,a                      ; HL = number * 4
    ld h,0
    add hl,hl
    add hl,hl
    ld a,h                      ; + high_scores
    ASSERT (high_scores & 0xFF) == 0
    add a,high_scores >> 8
    ld h,a
    ret

solved_bcd: DW 0                ; number of solved levels in BCD (0x0000-0x0100)

@code_save DEFL $
    ORG @uninit_save

; High scores: for each level, best pushes then best time, each a
; little-endian word of 4 BCD digits (time is 0xMMSS, minutes:seconds).
; NO_SCORE in both means the level isn't solved yet; it compares as worse
; than any real score. Set to NO_SCORE by init. On a page boundary (see
; high_score_address).
    ALIGN 0x100
high_scores:
    DS COUNT * 4
high_scores_end:

@uninit_save DEFL $
    ORG @code_save

    ENDMODULE
