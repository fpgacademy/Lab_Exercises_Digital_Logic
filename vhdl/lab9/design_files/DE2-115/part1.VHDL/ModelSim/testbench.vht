LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE Behavior OF testbench IS
    COMPONENT proc
        PORT ( DIN                 : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
               Resetn, Clock, Run  : IN  STD_LOGIC;
               Done                : BUFFER  STD_LOGIC);
    END COMPONENT;

    SIGNAL CLOCK_50 : STD_LOGIC := '0';
    SIGNAL Instruction : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL Resetn : STD_LOGIC := '0';
    SIGNAL Run, Done : STD_LOGIC;

    CONSTANT clock_period : TIME := 20 ns;
BEGIN
    U1: proc PORT MAP (DIN => Instruction, Resetn => Resetn, Clock => CLOCK_50, 
                       Run => Run, Done => Done);

    clock_process: PROCESS
    BEGIN
        CLOCK_50 <= '0';
        WAIT FOR clock_period / 2;
        CLOCK_50 <= '1';
        WAIT FOR clock_period / 2;
    END PROCESS;

    vectors: PROCESS
    BEGIN
        Run <= '0'; Instruction <= "0000000000000000"; 
        WAIT FOR 20 ns;
        Resetn <= '1'; Run <= '1'; Instruction <= "0001000000011100";  -- mv  r0, #28
        WAIT FOR 20 ns;
        Run <= '0';
        WAIT FOR 20 ns;
        Run <= '1'; Instruction <= "0011001011111111";  -- mvt r1, #0xFF00
        WAIT FOR 20 ns;
        Run <= '0';
        WAIT FOR 20 ns;
        Run <= '1'; Instruction <= "0101001011111111";  -- add r1, #0xFF
        WAIT FOR 20 ns;
        Run <= '0';
        WAIT FOR 60 ns;
        Run <= '1'; Instruction <= "0110001000000000";  -- sub r1, r0
        WAIT FOR 20 ns;
        Run <= '0';
        WAIT FOR 60 ns;
        Run <= '1'; Instruction <= "0101001000000001";  -- add r1, #1
        WAIT FOR 20 ns;
        Run <= '0';
        WAIT;
    END PROCESS;
END;
