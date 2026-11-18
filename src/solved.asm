; Solved screen: the play screen once every crate is on a target, with the
; header line highlighted, until fire returns to level select.

    MODULE Solved

; Stop the time, record the level's scores, and highlight the header.
; Entered from Play.update with nothing on the stack.
start:
    PROFILE_BORDER @Color.BLACK    ; not the colour of the screen we came from
    xor a                       ; stop the time
    ld (@Level.time_running),a
    call @Level.record_scores
    ld a,@Color.SOLVED_ATTR
    ld bc,0 << 8 | 0            ; row 0, all columns
    ld de,1 << 8 | 32
    call @Screen.paint_cells

event_loop:
    halt
    PROFILE_BORDER @Color.BLUE     ; drawing
    call @Play.draw             ; the last move's pushes and time
    PROFILE_BORDER @Color.RED      ; processing after the draw
    jp update                   ; may switch to another screen
update_return:
    PROFILE_BORDER @Color.BLACK    ; idle until the next frame
    jr event_loop

; Act on the inputs pressed (Input.get_pressed): fire returns to level
; select. Jumped to from event_loop, not called, so it can switch to
; another screen with nothing left on the stack.
; Entry: none.
; Exit: to LevelSelect.start, or to update_return.  Clobbers: A, HL.
update:
    call @Input.get_pressed
    bit @Input.FIRE,a
    jp nz,@LevelSelect.start
    jr update_return

    ENDMODULE
