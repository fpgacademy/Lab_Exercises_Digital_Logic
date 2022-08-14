MAIN:  mv    r0, #2
LOOP:  sub   r0, #1        // subtract to test bne
       bne   LOOP
       beq   T1            // r0 == 0, test beq
       mv    pc, #DEAD
T1:    mvt   r0, #0xFF
       add   r0, #0xFF     // r0 = 0xFFFF
       bcc   T2            // carry = 0, test bcc
       mv    pc, #DEAD
T2:    add   r0, #1
       bcs   T3            // carry = 1, test bcs
       mv    pc, #DEAD
T3:    bpl   T4
       mv    pc, #DEAD
T4:    add   r0, #-1
       bmi   T5
       mv    pc, #DEAD
T5:    b     MAIN
DEAD:  mv    pc, #DEAD
