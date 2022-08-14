.define LED_ADDRESS 0x10
.define HEX_ADDRESS 0x20

// shows on HEX displays either PASSEd or FAILEd
             mv     r2, #0                // used to count number of successful tests

             mv     r6, #T1               // save address of next test
             sub    r0, r0                // set the z flag
// test bne and beq
T1:          bne    FAIL                  // should not take the branch!
             mv     r6, #C1               // save address of next test
C1:          beq    C2                    // should take the branch
             mv     pc, #FAIL             // Argh!

C2:          add    r2, #2                // count the last two successful tests
             mv     r6, #T2               // save address of next test
// test bne and beq
T2:          bne    S1                    // should take the branch!
             mv     pc, #FAIL
S1:          mv     r6, #C3               // save address of next test
C3:          beq    FAIL                  // should not take the branch
             add    r2, #2                // count the last two successful tests

             mv     r6, #T3               // save address of next test
             mv     r3, #-1               // r3 = 0xFFFF
             add    r3, #1                // set the c flag
// test bcc and bcs
T3:          bcc    FAIL                  // should not take the branch!
             mv     r6, #C4               // save address of next test
C4:          bcs    C5                    // should take the branch
             mv     pc, #FAIL             // Argh!
C5:          add    r2, #2                // count the last two successful tests

             mv     r6, #T4
             mv     r3, #0
             add    r3, r3                // clear carry flag
// test bcc and bcs
T4:          bcc    S2                    // should take the branch!
             mv     pc, #FAIL
S2:          mv     r6, #C6               // save address of next test
C6:          bcs    FAIL                  // should not take the branch!
             add    r2, #2                // count the last two successes

             mv     r6, #T5               // save address of next test
			 mv		r3, #0
			 add	r3, #-1
// test bpl and bmi
T5:          bpl    FAIL                  // should not take the branch!
             mv     r6, #C7               // save address of next test
C7:          bmi    C8                    // should take the branch
             mv     pc, #FAIL             // Argh!
C8:          add    r2, #2                // count the last two successful tests

             mv     r6, #T6
             mv     r3, #0
             add    r3, r3                // clear negative flag
// test bpl and bmi
T6:          bpl    S3                    // should take the branch!
             mv     pc, #FAIL
S3:          mv     r6, #C9               // save address of next test
C9:          bmi    FAIL                  // should not take the branch!
             add    r2, #2                // count the last two successes

// finally, test ld and st from/to memory
             mv     r6, #T7               // save address of next test
             mv     r4, #_LDTEST
             ld     r4, [r4]
             mv     r3, #0x0A5
             sub    r3, r4
T7:          bne    FAIL                  // should not take the branch!
             add    r2, #1                // incr success count

             mv     r6, #T8               // save address of next test
             mv     r3, #0x0A5
             mv     r4, #_STTEST
             st     r3, [r4]        
             ld     r4, [r4]
             sub    r3, r4
T8:          bne    FAIL                  // should not take the branch!
             add    r2, #1                // incr success count

             mv     pc, #PASS

// Loop over the six HEX displays
FAIL:        mvt    r3, #LED_ADDRESS
             st     r6, [r3]              // show address of failed test on LEDs
             mv     r5, #_FAIL
             mv     pc, #PRINT
PASS:        mvt    r3, #LED_ADDRESS
             st     r2, [r3]              // show success count on LEDs
             mv     r5, #_PASS

PRINT:       mvt    r4, #HEX_ADDRESS      // address of HEX0 
             // We would normally use a loop counting down from 6 with mvne to display the
             // six letters. But in this testing code we can't assume that mvne even works!
             ld     r3, [r5]              // get letter 
             st     r3, [r4]              // send to HEX display
             add    r5, #1                // ++increment character pointer 
             add    r4, #1                // point to next HEX display
             ld     r3, [r5]              // get letter 
             st     r3, [r4]              // send to HEX display
             add    r5, #1                // ++increment character pointer 
             add    r4, #1                // point to next HEX display
             ld     r3, [r5]              // get letter 
             st     r3, [r4]              // send to HEX display
             add    r5, #1                // ++increment character pointer 
             add    r4, #1                // point to next HEX display
             ld     r3, [r5]              // get letter 
             st     r3, [r4]              // send to HEX display
             add    r5, #1                // ++increment character pointer 
             add    r4, #1                // point to next HEX display
             ld     r3, [r5]              // get letter 
             st     r3, [r4]              // send to HEX display
             add    r5, #1                // ++increment character pointer 
             add    r4, #1                // point to next HEX display
             ld     r3, [r5]              // get letter 
             st     r3, [r4]              // send to HEX display
             add    r5, #1                // ++increment character pointer 
             add    r4, #1                // point to next HEX display
            
HERE:        mv     pc, #HERE

_PASS:      .word   0b0000000001011110    // d
            .word   0b0000000001111001    // E
            .word   0b0000000001101101    // S
            .word   0b0000000001101101    // S
            .word   0b0000000001110111    // A
            .word   0b0000000001110011    // P

_FAIL:      .word   0b0000000001011110    // d
            .word   0b0000000001111001    // E
            .word   0b0000000000111000    // L
            .word   0b0000000000110000    // I
            .word   0b0000000001110111    // A
            .word   0b0000000001110001    // F

_LDTEST:    .word   0x0A5
_STTEST:    .word   0x05A
