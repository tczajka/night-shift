; Profiling aids, enabled by assembling with -DPROFILE (`make PROFILE=1`).
;
; PROFILE_BORDER sets the border colour, so the border shows which part of
; the code the CPU is in as the beam draws each line (one line is 224
; T-states). Without PROFILE it assembles to nothing.
;
; Defines macros only and emits no bytes, so it is included before the code.

; Set the border colour (0-7) when profiling.
; Clobbers: A. Flags are preserved.
    MACRO PROFILE_BORDER colour
        IFDEF PROFILE
            ld a,colour
            out (0xFE),a        ; bits 3-4 (tape out, speaker) stay 0
        ENDIF
    ENDM
