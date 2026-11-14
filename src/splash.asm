; Splash screen: the loading screen is still displayed when the code starts,
; so just wait for fire.

    MODULE Splash

start:
    call @Input.reset           ; ignore inputs held from before the splash
    ei                          ; initialization done: start scanning input
.wait:
    halt
    call @Input.get_pressed
    bit @Input.FIRE,a
    jr z,.wait
    jp @LevelSelect.start

    ENDMODULE
