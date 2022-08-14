START:  mv    r0, #4
        mv    r4, =0x0F0F
        lsl   r4, #1        // lsl with Op2 = #D
        lsr   r4, #1        // lsr with Op2 = #D
        lsl   r4, r0        // lsl with Op2 = rY
        asr   r4, #1        // asr with Op2 = #D
        ror   r4, r0        // ror with Op2 = rY
END:    b     END
