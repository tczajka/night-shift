; The current level: its number, high scores, board, pushes and time.

    MODULE Level

; The board, in squares. A position is row * WIDTH + column.
WIDTH       EQU 16
HEIGHT      EQU 11

; Bits of a board square.
WALL        EQU 0x01
FLOOR       EQU 0x02            ; inside the walls (reachable from the start)
TARGET      EQU 0x04
CRATE       EQU 0x08

NO_SQUARE   EQU 0xFF            ; not a position
    ASSERT WIDTH * HEIGHT <= NO_SQUARE

; Make a level the current one: set `number_bcd` and `number`, and copy its
; high scores to `best_pushes` and `best_time`.
; Entry: A = level number in BCD (0x00-0x99).
; Exit: none.  Clobbers: A, BC, DE, HL.
select:
    ld (number_bcd),a
    call @Math.from_bcd
    ld (number),a
    call @Levels.high_score_address
    ld de,best_pushes
    ld bc,4                     ; pushes and time
    ldir
    ret

; Load the current level (`number`) from the level data (Levels.data): set
; up the board (see mark_floor) and the bulldozer, facing right, and set the
; pushes and time to 0. Call it with the time stopped (`time_running`
; clear).
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL.
load:
    ld a,(number)
    call @Levels.address

    ld c,(hl)                   ; C = number of crates (and of targets)
    inc hl
    ld a,(hl)
    ld (bulldozer),a
    inc hl

    ; Walls: 1 bit per square, bit 7 first; this writes every square.
    ld de,board                 ; E = position
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

    call mark_floor

    xor a
    ASSERT @Math.RIGHT == 0
    ld (facing),a
    ld (time_frames),a
    ld h,a
    ld l,a
    ld (pushes),hl
    ld (time),hl
    ret

; Mark the floor: set FLOOR on every square the bulldozer could reach if
; nothing were in the way, i.e. the squares inside the walls. A flood fill
; from the bulldozer, with the squares still to visit kept on the stack
; (at most 4 per square, plus the NO_SQUARE marker: 1 + 4 * 11 * 16 words
; = 0x582 bytes).
; Entry: the walls and the bulldozer set up.  Exit: none.
; Clobbers: A, BC, DE, HL.
mark_floor:
    ld h,board >> 8
    ld e,NO_SQUARE              ; marks the bottom of the squares to visit
    push de
    ld a,(bulldozer)
    ld l,a
.visit:                         ; L = position
    ld a,(hl)
    and WALL | FLOOR
    jr nz,.next                 ; a wall, or already marked
    ld a,(hl)
    or FLOOR
    ld (hl),a

    ; Visit the 4 neighbours. The walls enclose the floor, so they are all
    ; on the board.
    ld bc,offsets
.neighbour:
    ld a,(bc)
    add a,l
    ld e,a
    push de
    inc bc
    ld a,c
    cp offsets_end & 0xFF
    jr nz,.neighbour

.next:
    pop de
    ld l,e
    ld a,e
    cp NO_SQUARE
    jr nz,.visit
    ret

; If `time_running`, advance the current level's time by 1/50 of a second,
; i.e. one frame: count frames in time_frames, and every 50 add a second
; to time. The time stops at 99:59. Called by the frame interrupt.
; Entry: none.  Exit: none.  Clobbers: A, HL.
time_tick:
    ld a,(time_running)
    or a
    ret z                       ; stopped
    ld hl,time_frames
    inc (hl)
    ld a,(hl)
    cp 50
    ret c                       ; not a whole second yet
    ld (hl),0
    ld hl,(time)                ; H = minutes, L = seconds
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
    ld (time),hl
    ret

; Position offset of a step in each direction, indexed by the Math
; directions.
offsets:
    DB 1, -1, WIDTH, -WIDTH
offsets_end:
    ASSERT offsets_end - offsets == 4
    ASSERT @Math.RIGHT == 0 && @Math.LEFT == 1
    ASSERT @Math.DOWN == 2 && @Math.UP == 3

; The current level.
number_bcd: DB 0                ; level number in BCD
number:     DB 0                ; level number in binary
; Its high scores, laid out like an entry of Levels.high_scores.
best_pushes: DW @Levels.NO_SCORE
best_time:   DW @Levels.NO_SCORE
    ASSERT best_time == best_pushes + 2
time_running: DB 0              ; nonzero: time_tick advances the time

@code_cur DEFL $
    ORG @uninit_cur

; The current level, set up by load.
; Board: 16x11 squares, row by row, one byte each, made of WALL, FLOOR,
; TARGET and CRATE. On a page boundary, so the low byte of a square's
; address is its position (row * 16 + column).
    ALIGN 0x100
board:
    DS WIDTH * HEIGHT
board_end:
    ASSERT board_end - board <= 0x100
bulldozer:   DS 1               ; position of the bulldozer
facing:      DS 1               ; direction it faces: Math.RIGHT, LEFT, DOWN or UP
pushes:      DS 2               ; pushes so far, BCD
time:        DS 2               ; time so far, BCD 0xMMSS (minutes:seconds)
time_frames: DS 1               ; frames (1/50 s) since `time` last changed, 0-49

@uninit_cur DEFL $
    ORG @code_cur

    ENDMODULE
