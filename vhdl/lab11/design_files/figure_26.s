START:  mvt   sp, #0x10      // sp = 0x1000 = 4096
        mv    r4, =0x0F0F    
        push  r4
        bl    SUBR
        pop   r4
END:    b     END

SUBR:   sub   r4, r4
        mv    pc, lr
