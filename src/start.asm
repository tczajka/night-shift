; Entry point, called by the BASIC loader (see tape.asm).

    MODULE Start

start:
    di                          ; no ROM interrupt handler while initializing
    ld sp,@Memory.stack_end     ; leave the BASIC stack; no return to BASIC
    call @Interrupt.init
    call @Levels.init
    call @Anim.init
    ei                          ; initialized: start our frame interrupt
    jp @Splash.start

    ENDMODULE
