; Levels and their high scores (see Alloc.high_scores).

    MODULE Level

COUNT       EQU 100             ; levels are numbered 00-99
NO_SCORE    EQU 0xFFFF          ; pushes and time of a level not solved yet

; The board (Alloc.board), in squares. A position is row * WIDTH + column.
WIDTH       EQU 16
HEIGHT      EQU 11

; Bits of a board square.
WALL        EQU 0x01
TARGET      EQU 0x02
CRATE       EQU 0x04

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

; Make a level the current one: set `number_bcd` and `number`, and copy its
; high scores to `best_pushes` and `best_time`.
; Entry: A = level number in BCD (0x00-0x99).
; Exit: none.  Clobbers: A, BC, DE, HL.
select:
    ld (number_bcd),a
    call @Math.from_bcd
    ld (number),a
    call high_score_address
    ld de,best_pushes
    ld bc,4                     ; pushes and time
    ldir
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

; Load the current level (`number`) from the level data (`levels` in
; main.asm): set up the board and the bulldozer, and set the pushes and
; time to 0. Call it with the time stopped (`time_running` clear).
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
load:
    ld a,(number)               ; HL = the level's index entry
    add a,a
    ld l,a
    ASSERT (@levels & 0xFF) == 0
    ASSERT 2 * COUNT <= 0x100   ; the index is within the page
    ld h,@levels >> 8
    ld e,(hl)                   ; HL = levels + the level's offset
    inc l
    ld a,(hl)
    add a,@levels >> 8
    ld h,a
    ld l,e

    ld c,(hl)                   ; C = number of crates (and of targets)
    inc hl
    ld a,(hl)
    ld (@Alloc.bulldozer),a
    inc hl

    ; Walls: 1 bit per square, bit 7 first; this writes every square.
    ld de,@Alloc.board          ; E = position
    ld b,WIDTH * HEIGHT / 8
.wall_byte:
    push bc
    ld c,(hl)
    inc hl
    ld b,8
.wall_bit:
    xor a
    sla c                       ; next bit into carry
    ASSERT WALL == 1
    rla                         ; A = WALL or 0
    ld (de),a
    inc e
    djnz .wall_bit
    pop bc
    djnz .wall_byte

    ; Targets, then crates: C positions each (at least 1).
    ld b,c
.target:
    ld e,(hl)
    inc hl
    ld a,(de)
    or TARGET
    ld (de),a
    djnz .target
    ld b,c
.crate:
    ld e,(hl)
    inc hl
    ld a,(de)
    or CRATE
    ld (de),a
    djnz .crate

    xor a
    ld (@Alloc.time_frames),a
    ld h,a
    ld l,a
    ld (@Alloc.pushes),hl
    ld (@Alloc.time),hl
    ret

; If `time_running`, advance the current level's time by 1/50 of a second,
; i.e. one frame: count frames in Alloc.time_frames, and every 50 add a
; second to Alloc.time. The time stops at 99:59. Called by the frame
; interrupt.
; Entry: none.  Exit: none.  Clobbers: A, HL.
time_tick:
    ld a,(time_running)
    or a
    ret z                       ; stopped
    ld hl,@Alloc.time_frames
    inc (hl)
    ld a,(hl)
    cp 50
    ret c                       ; not a whole second yet
    ld (hl),0
    ld hl,(@Alloc.time)         ; H = minutes, L = seconds
    ld a,l
    add a,1                     ; next second, in BCD
    daa
    cp 0x60
    jr c,.seconds_done
    ld a,h                      ; seconds 59 -> 00: next minute
    cp 0x99
    ret z                       ; already 99:59: stay there
    add a,1
    daa
    ld h,a
    xor a
.seconds_done:
    ld l,a
    ld (@Alloc.time),hl
    ret

solved_bcd: DW 0                ; number of solved levels in BCD (0x0000-0x0100)

; The current level.
number_bcd: DB 0                ; level number in BCD
number:     DB 0                ; level number in binary
; Its high scores, laid out like an entry of Alloc.high_scores.
best_pushes: DW NO_SCORE
best_time:   DW NO_SCORE
    ASSERT best_time == best_pushes + 2
time_running: DB 0              ; nonzero: time_tick advances the time

    ENDMODULE
