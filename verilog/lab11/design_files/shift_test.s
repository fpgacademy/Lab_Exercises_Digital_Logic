DEPTH 4096
.define LED_ADDRESS 0x1000
.define HEX_ADDRESS 0x2000
.define SW_ADDRESS  0x3000

// this code tests the lsl, lsr, asr, and ror instructions. The type of operation is
// selected with SW[6:5] (00 == lsl, 01 == lsr, 10 = asr, 11 == ror). The processor must
// be reset each time these switches are changed, to restart the code.
// The value to be shifted is displayed on HEX3-0; this value is placed into r0 at the 
// start of the code. The amount to be shifted in each loop iteration is set by SW[3:0].
START: mv   sp, =0x1000       // initialize sp to bottom of memory

MAIN:  mv   r0, =0x9010
       bl   REG               // display r0 on HEX3-0
       bl   DELAY
LOOP:  mv   r1, =SW_ADDRESS
       ld   r1, [r1]
       mv   r2, =LED_ADDRESS
       st   r1, [r2]
       mv   r2, r1
       lsr  r2, #5            // get shift type (SW bits 6:5)

       cmp  r2, #0b00
       bne  LSR
       lsl  r0, r1
       b    CONT
LSR:   cmp  r2, #0b01
       bne  ASR
       lsr  r0, r1
       b    CONT
ASR:   cmp  r2, #0b10
       bne  ROR
       asr  r0, r1
       b    CONT
ROR:   ror  r0, r1

CONT:  bl   REG
       bl   DELAY

       cmp  r0, #0
       beq  MAIN
       cmp  r0, #-1
       beq  MAIN

END:   b    LOOP

// causes a delay
DELAY: push r1
       push r2
// the delay loop below works well for DESim. Use a longer delay if running on actual 
// hardware
       mvt  r2, #0          // change #0 to #2 for hardware
OUTER: mvt  r1, #0x10       // r1 <- 2^12 = 4096
WAIT:  sub  r1, #1
       bne  WAIT
       cmp  r2, #0
       beq  DONE
       sub  r2, #1
       b    OUTER
DONE:  pop  r2
       pop  r1
       mv   pc, lr

// subroutine that displays register r0 (in hex) on HEX3-0 
REG:   push r1
       push r2
       push r3

       mv   r2, =HEX_ADDRESS  // point to HEX0

       mv   r3, #0            // used to shift digits
DIGIT: mv   r1, r0            // the register to be displayed
       lsr  r1, r3            // isolate digit
       and  r1, #0xF          // "    "  "  "
       add  r1, #SEG7         // point to the codes
       ld   r1, [r1]          // get the digit code
       st   r1, [r2]
       add  r2, #1            // point to next HEX display
       add  r3, #4            // for shifting to the next digit
       cmp  r3, #16           // done all digits?
       bne  DIGIT
       
       pop  r3
       pop  r2
       pop  r1
       mv   pc, lr

SEG7:  .word 0b00111111       // '0'
       .word 0b00000110       // '1'
       .word 0b01011011       // '2'
       .word 0b01001111       // '3'
       .word 0b01100110       // '4'
       .word 0b01101101       // '5'
       .word 0b01111101       // '6'
       .word 0b00000111       // '7'
       .word 0b01111111       // '8'
       .word 0b01100111       // '9'
       .word 0b01110111       // 'A' 1110111
       .word 0b01111100       // 'b' 1111100
       .word 0b00111001       // 'C' 0111001
       .word 0b01011110       // 'd' 1011110
       .word 0b01111001       // 'E' 1111001
       .word 0b01110001       // 'F' 1110001
