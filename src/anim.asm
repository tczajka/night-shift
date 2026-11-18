; Animation tiles, precomputed at startup (init).
;
; A move slides the bulldozer, and a crate it pushes, to the next square
; in FRAMES frames, 1 pixel per frame. In each frame at most 3 squares in
; a line change: the one the bulldozer leaves, the one it enters (which a
; pushed crate leaves) and the one a pushed crate enters. `tiles` holds the
; picture of each such square (a 16x16 tile in the Sprite format) for each
; direction, frame and kind of square, so drawing a move only copies tiles.
;
; Frame f (1 to FRAMES) shows the objects moved f pixels, so the last frame
; shows them on their new squares. The bulldozer's tracks are in phase
; f mod Sprite.TRACK_PHASES (see Sprite.bulldozer).

    MODULE Anim

FRAMES      EQU 16              ; frames per move, 1 pixel each

; Kinds of square in a move, in the order of their tiles in a frame:
LEAVE_FLOOR  EQU 0              ; the bulldozer leaving floor
LEAVE_TARGET EQU 1              ; the bulldozer leaving a target
ENTER_FLOOR  EQU 2              ; the bulldozer entering floor
ENTER_TARGET EQU 3              ; the bulldozer entering a target
PUSH         EQU 4              ; the bulldozer entering where the crate it
                                ; pushes leaves: they cover all of it, so
                                ; floor and target look the same
CRATE_FLOOR  EQU 5              ; a pushed crate entering floor
CRATE_TARGET EQU 6              ; a pushed crate entering a target
KINDS        EQU 8              ; tiles per frame: 7 used, 1 spare

@code_save DEFL $
    ORG @uninit_save

; The tiles: for each direction (Math.RIGHT, LEFT, DOWN, UP), each frame
; (1 to FRAMES) and each kind, the tile is at
; tiles + (direction * FRAMES + frame - 1) * 0x100 + kind * 0x20: one page
; per direction and frame.
    ALIGN 0x100
tiles:
    DS 4 * FRAMES * KINDS * 0x20
tiles_end:
    ASSERT KINDS * 0x20 == 0x100

; Work areas for init.
direction:  DS 1                ; the direction being done
frame:      DS 1                ; the frame being done, 1 to FRAMES
; Each object split in two in the frame being done (see split): the part in
; the square it leaves (LEAVING), then the part in the square it enters
; (ENTERING). The solid square's parts are where any object covers.
bulldozer_parts: DS 0x40
crate_parts:     DS 0x40
solid_parts:     DS 0x40
solid:      DS 0x20             ; a solid square: all ink
zeros:      DS 0x20             ; an empty square (floor): all paper
column:     DS 0x60             ; for split: zeros, a sprite, zeros
column_end:

@uninit_save DEFL $
    ORG @code_save

LEAVING     EQU 0               ; offsets in the parts (see bulldozer_parts)
ENTERING    EQU 0x20

; How to make each kind of tile, in kind order: three addresses of tiles,
; an object's part, a background and a mask, combined as
; object | (background & mask). The mask is where the object doesn't
; cover the square. In a square's own coordinates, where a moving object
; doesn't cover the square it leaves is where it covers the square it
; enters, and the other way round: so the mask is the solid square's other
; part.
recipes:
    DW bulldozer_parts + LEAVING, zeros, solid_parts + ENTERING
    DW bulldozer_parts + LEAVING, @Sprite.target, solid_parts + ENTERING
    DW bulldozer_parts + ENTERING, zeros, solid_parts + LEAVING
    DW bulldozer_parts + ENTERING, @Sprite.target, solid_parts + LEAVING
    DW bulldozer_parts + ENTERING, crate_parts + LEAVING, solid_parts + LEAVING
    DW crate_parts + ENTERING, zeros, solid_parts + LEAVING
    DW crate_parts + ENTERING, @Sprite.target, solid_parts + LEAVING
recipes_end:

; Fill `tiles`. Takes under a second (counted: about 2.6 million T-states).
; Entry: none.  Exit: none.  Clobbers: A, BC, DE, HL, IX, IY.
init:
    ld hl,solid
    ld bc,0x20
    ld a,0xFF
    call @Memory.fill
    ASSERT column == zeros + 0x20   ; clear both
    ld hl,zeros
    ld bc,column_end - zeros
    xor a
    call @Memory.fill

    ld iy,tiles                 ; IY = the next tile
    ASSERT @Math.RIGHT == 0 && @Math.LEFT == 1
    ASSERT @Math.DOWN == 2 && @Math.UP == 3
    xor a
    ld (direction),a
.direction:
    ld a,1
    ld (frame),a
.frame:
    ld hl,solid
    ld de,solid_parts
    call split
    ld hl,@Sprite.crate
    ld de,crate_parts
    call split

    ; The bulldozer facing `direction`, its tracks in phase
    ; frame mod TRACK_PHASES: HL = Sprite.bulldozer
    ; + (direction * TRACK_PHASES + phase) * 0x20.
    ASSERT @Sprite.TRACK_PHASES == 4    ; a power of 2, for AND
    ld a,(direction)
    add a,a
    add a,a
    ld b,a
    ld a,(frame)
    and @Sprite.TRACK_PHASES - 1
    or b
    ld l,a
    ld h,0
    DUP 5                       ; * 0x20
    add hl,hl
    EDUP
    ld de,@Sprite.bulldozer
    add hl,de
    ld de,bulldozer_parts
    call split

    ld hl,recipes
.tile:
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    push de
    pop ix                      ; IX = the object's part
    ld c,(hl)
    inc hl
    ld b,(hl)                   ; BC = the background
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)                   ; DE = the mask
    inc hl
    push hl
    ld h,b
    ld l,c
    call combine
    pop hl
    ld a,l
    cp recipes_end & 0xFF
    jr nz,.tile
    ld de,(KINDS - 7) * 0x20    ; skip the spare tile
    add iy,de

    ld hl,frame
    inc (hl)
    ld a,(hl)
    cp FRAMES + 1
    jp nz,.frame
    ld hl,direction
    inc (hl)
    ld a,(hl)
    cp 4
    jp nz,.direction
    ret

; Split a sprite moved `frame` pixels in `direction` from its square into
; its two parts: the part still in the square it leaves and the part in the
; square it enters, each a tile in its square's own coordinates, empty
; where the sprite isn't.
; Entry: HL = sprite, DE = where to put the parts: leaving at DE, entering
; at DE + 0x20.
; Exit: none.  Clobbers: A, BC, DE, HL, IX.
split:
    ld a,(direction)
    cp @Math.DOWN
    jr nc,.vertical

    ; Right or left: shift each row of the sprite `frame` pixels, through
    ; 32 bits that span both squares.
    push iy
    push hl
    pop ix                      ; IX = the sprite's row
    push de
    pop iy                      ; IY = the leaving part's row
    ld c,16                     ; rows
.row:
    ld a,(frame)
    ld b,a
    ld a,(direction)
    ASSERT @Math.RIGHT == 0
    or a
    jr nz,.left
    ld d,(ix+0)                 ; right: from DE (leaving) into HL (entering)
    ld e,(ix+1)
    ld hl,0
.shift_right:
    srl d
    rr e
    rr h
    rr l
    djnz .shift_right
    ex de,hl
    jr .store
.left:
    ld h,(ix+0)                 ; left: from HL (leaving) into DE (entering)
    ld l,(ix+1)
    ld de,0
.shift_left:
    sla l
    rl h
    rl e
    rl d
    djnz .shift_left
.store:                         ; HL = the leaving row, DE = the entering row
    ld (iy+0),h
    ld (iy+1),l
    ld (iy+ENTERING),d
    ld (iy+ENTERING+1),e
    inc ix
    inc ix
    inc iy
    inc iy
    dec c
    jr nz,.row
    pop iy
    ret

    ; Down or up: put the sprite between 16 rows of zeros above and below
    ; in `column`, and take each part as 16 rows from there. The sprite is
    ; at rows 16-31 of the column. Moving down, the leaving part starts at
    ; row 16 - frame and the entering part 16 rows after it; moving up,
    ; the leaving part starts at row 16 + frame and the entering part 16
    ; rows before it.
.vertical:
    push de
    ld de,column + 0x20
    ld bc,0x20
    ldir
    ld a,(frame)                ; BC = frame rows (B = 0 after the LDIR)
    add a,a
    ld c,a
    ld hl,column + 0x20
    ld a,(direction)
    cp @Math.UP
    jr z,.up
    or a
    sbc hl,bc
    jr .leaving
.up:
    add hl,bc
.leaving:                       ; HL = the leaving part's first row
    pop de
    ld bc,0x20
    ldir
    ld a,(direction)            ; down: the entering part follows
    cp @Math.UP
    jr nz,.entering
    ld bc,-0x40                 ; up: it starts 16 rows before the leaving
    add hl,bc
.entering:
    ld bc,0x20
    ldir
    ret

; Make a tile, byte by byte: object | (background & mask).
; Entry: IX = object, HL = background, DE = mask, IY = where to put it.
; Exit: IY = just after the tile.  Clobbers: A, B, DE, HL, IX.
combine:
    ld b,0x20
.byte:
    ld a,(de)
    and (hl)
    or (ix+0)
    ld (iy+0),a
    inc de
    inc hl
    inc ix
    inc iy
    djnz .byte
    ret

    ENDMODULE
