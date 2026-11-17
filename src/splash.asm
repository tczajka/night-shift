; Splash screen: the loading screen is still displayed when the code starts,
; so just wait for fire.

    MODULE Splash

start:
    PROFILE_BORDER @Color.BLACK    ; not the colour of the screen we came from
    call @Input.reset           ; ignore inputs held from before the splash
.wait:
    halt
    call @Input.get_pressed
    bit @Input.FIRE,a
    jr z,.wait
    jp @LevelSelect.start

    ENDMODULE
