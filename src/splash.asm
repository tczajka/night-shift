; Splash screen: the loading screen is still displayed when the code starts,
; so just wait for fire.

    MODULE Splash

start:
    call @Input.get_pressed     ; ignore presses from before the splash
.wait:
    halt
    call @Input.get_pressed
    bit @Input.FIRE,a
    jr z,.wait
    jp @LevelSelect.start

    ENDMODULE
