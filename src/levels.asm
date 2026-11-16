; The levels: the level data and the levels' high scores (see
; Alloc.high_scores).

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
    ld hl,@Alloc.high_scores
    ld bc,@Alloc.high_scores_end - @Alloc.high_scores
    ASSERT NO_SCORE == 0xFFFF   ; both bytes the same
    ld a,NO_SCORE & 0xFF
    call @Memory.fill

    ; TEMPORARY: level 13 solved in 2718 pushes, 31:41.
.TEST_SCORE EQU @Alloc.high_scores + 13 * 4
    ld hl,0x2718
    ld (.TEST_SCORE),hl         ; pushes
    ld hl,0x3141
    ld (.TEST_SCORE + 2),hl     ; time
    ld hl,0x0001
    ld (solved_bcd),hl
    ret

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

; Address of a level's entry in Alloc.high_scores.
; Entry: A = level number in binary (0-99).
; Exit: HL = address.  Clobbers: A.
high_score_address:
    ld l,a                      ; HL = number * 4
    ld h,0
    add hl,hl
    add hl,hl
    ld a,h                      ; + high_scores
    ASSERT (@Alloc.high_scores & 0xFF) == 0
    add a,@Alloc.high_scores >> 8
    ld h,a
    ret

solved_bcd: DW 0                ; number of solved levels in BCD (0x0000-0x0100)

    ENDMODULE
