To install and use the assembler:

1)  First install Python version 3 from the website python.org. Make sure that the 
    installer updates your Path environment variable. It should include the folder 
    where python is installed, for example C:\Python3, as well as the folder that 
    is used for python scripts, for example C:\Python3\Scripts.  If these two folders 
    are not added to your path during installation, then add them manually by editing 
    the environment variables on your computer.

2)  The Assembler consists of one python script, named sbasm.py. Copy the sbasm.py file
    into the Scripts folder that is inside the folder where you installed python. For 
    example, if you installed python into the folder C:\Python3, then copy sbasm.py into 
    the folder C:\Python3\Scripts.

    This completes the installation process!

    Now, in a Command prompt window you can navigate to any folder that contains your 
    assembly-language code, such as file.s, and assemble it by typing

    sbasm.py file.s file.mif

    By default, the Windows OS associates any file *.py with the python executable program.
    Thus, Windows will automatically execute the command "python sbasm.py file.s file.mif". 
    Windows uses your Path environment variable to find the sbasm.py script. 

*****************************************************************************************
Notes
-----

1) Assembly Language File Format

    The input file line numbers start indexing at line number 1 (for error messages). Blank 
    lines are ignored.

    // is used for comments, the assembler will ignore everything after the //
    
    Supported instructions are:
    ---------------------------

    mv rX, rY      rX <- rY
    mv rX, #D      rX <- D
    b{cond} L      branch with {optional} condition (L is label)
                   cond: none, eq, ne, cc, cs, pl, mi, and l
                   bl is a subroutine call. It uses r6 (aka lr) as a link register 
    mvt rX, #D     rX <- DDDDDDDD00000000
    add rX, rY     rX <- rX + rY
    add rX, #D     rX <- rX + D
    sub rX, rY     rX <- rX - rY
    sub rX, #D     rX <- rX - D
    ld rX, [rY]    rX <- contents of memory at address in rY
    pop rX         rX <- contents of memory at address in r5, then r5++
    st rX, [rY]    contents of memory at address in rY <- rX
    push rX        --r5, then memory at address in r5 <- rX
    and rX, rY     rX <- rX & rY
    and rX, #D     rX <- rX & D
    cmp rX, rY     performs rX - rY to sets flags
    cmp rX, #D     performs rX - D to set flags
    lsl rX, rY     shifts rX left the number of times specified in rY[3:0]
                   -- msb shifted into the C flag
    lsl rX, #D     shifts rX left D times
                   -- msb shifted into the C flag
    lsr rX, rY     shifts rX right the number of times specified in rY[3:0]
                   -- 0 shifted in
    lsr rX, #D     shifts rX right D times
                   -- 0 shifted in
    asr rX, rY     shifts rX right the number of times specified in rY[3:0]
                   -- msb shifted in
    asr rX, #D     shifts rX right D times
                   -- msb shifted in
    ror rX, rY     rotates rX right the number of times specified in rY[3:0]
    ror rX, #D     rotates rX right D times

    rX and rY can be registers r0, r1, ..., r7. Register r5 can also be called
    sp (stack pointer), r6 can be called lr (link register), and r7 can be
    called pc (program counter)

    Supported pseudo-instructions are:
    ----------------------------------

    mv rX, =D      rX <- D

    This pseudo instruction assembles into two machine-code words corresponding to: 
    
    mvt rX, #D[15:8]
    add rX, #D[7:0]

2)  Running the program:
    The program expects 2 arguments in particular order:
        The input file name (the file with the assembly code written).
        The output file name (the file where the MIF is produced).
    
    Example:
        sbasm.py input_file.s output_file.mif
        sbasm.py input_file.s                        // produces output file a.mif

4)  Bit width

    The Assembler supports a bit width of 16

    The Assembler supports different memory depths. The default is 256 words, but can 
    be changed by including in your assembly-language program the line

    DEPTH = x   (only integer multiples of 2 supported)

    Machine code instructions output by the assembler use the encodings:
    
    15              0
     III0XXX000000YYY
     III1XXXDDDDDDDDD
     III1XXX0DDDDDDDD
     III0XXX10SS00YYY
     III0XXX10SS0DDDD

    Where III specifies the instruction, XXX is rX, YYY is rY, and DDDDDDDDD is
    #D. For mvt the immediate is 0DDDDDDDD. For b{cond} XXX is the condition.
    For shift instructions SS = 00 (lsl), 01 (lsr), 10 (asr), 11 (ror), and 
    DDDD is the shift/rotate amount.

5)  Instruction Encoding
    mv rX, rY:    0000XXX000000YYY
    mv rX, #D:    0001XXXDDDDDDDDD
    b{cond} Lab:  0010CCCDDDDDDDDD, where DDDDDDDDD is the 2's complement offset
        needed to reach Lab from the current pc+1 (pc is assumed to be already
        incremented by 1 before adding the offset). The condition CCC = 000 (none),
        001 (eq), 010 (ne), 011 (cc), 100 (cs), 101 (pl), 110 (mi), or 111 (l).
    mvt rX, #D:   0011XXX0DDDDDDDD
    add rX, rY:   0100XXX000000YYY
    add rX, #D:   0101XXXDDDDDDDDD
    sub rX, rY:   0110XXX000000YYY
    sub rX, #D:   0111XXXDDDDDDDDD
    ld rX, [rY]:  1000XXX000000YYY
    pop rX:       1001XXX000000101 (101 refers to register r5 = sp)
    st rX, [rY]:  1010XXX000000YYY
    push rX:      1011XXX000000101 (101 refers to register r5 = sp)
    and rX, rY:   1100XXX000000YYY
    and rX, #D:   1101XXXDDDDDDDDD
    cmp rX, rY:   1110XXX000000YYY
    cmp rX, #D:   1111XXXDDDDDDDDD
    lsl rX, rY:   1110XXX100000YYY
    lsl rX, #D:   1110XXX11000DDDD
    lsr rX, rY:   1110XXX100100YYY
    lsr rX, #D:   1110XXX11010DDDD
    asr rX, rY:   1110XXX101000YYY
    asr rX, #D:   1110XXX11100DDDD
    ror rX, rY:   1110XXX101100YYY
    ror rX, #D:   1110XXX11110DDDD

6) Assembler Directives and Labels

    The Assembler supports two directives: .define and .word.

    The .define directive is used to associate a symbolic name with a constant.
    For example, if your assembly-language code includes the line

    .define STACK 255            // bottom of memory

    Then your program could use this symbolic name STACK in an instruction such as

    mv     r5, #STACK            // stack pointer

    The default number base is 10, as used for STACK above. Other examples are

    .define SW_ADDRESS 0x3000         // hexadecimal
    .define HEX_ADDRESS 0x2000        // hexadecimal
    .define LED_ADDRESS 0x1000        // hexadecimal
    .define PATTERN 0b00111111        // binary
    
    Any line of assembly-language code can include a LABEL, which can use the 
    characters a-z, A-Z, 0-9, _, or $. Here is an example that uses labels:

    MAIN:  mv    r0, #TENk       // get address of data
           ld    r0, [r0]        // load data
             ...
             ...
           b     MAIN
    TENk:  .word 10000

    The assembler supports signed values. The range of positive immediate data is
    0 to 255 (0x0 to 0xFF). The range of negative immediate data is -1 to -256
    (0xFFFF to 0xFF00).

    The .word directive is used to place data into memory, normally at the end of an 
    assembly-language source-code file. For example, if your assembly-language code 
    includes the lines

    DATA:   .word 0b00111111
            .word 0b00000110
            .word 0xFF
            .word 65535         // largest unsigned number
            .word 32767         // largest signed +ve number
            .word -1            // assembles to 0xFFFF
            .word -32768        // largest signed -ve number (0x8000)

    These data words (extended to 16 bits) will appear in the resulting .MIF file.

