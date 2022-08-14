LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE Behavior OF testbench IS
    COMPONENT part8
        PORT (  KEY                                : IN   STD_LOGIC_VECTOR(0 DOWNTO 0);
                SW                                 : IN   STD_LOGIC_VECTOR(9 DOWNTO 0);
                CLOCK_50                           : IN   STD_LOGIC;
                HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
                LEDR                               : OUT  STD_LOGIC_VECTOR(9 DOWNTO 0) );
    END COMPONENT;

    SIGNAL CLOCK_50 : STD_LOGIC;
    SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL KEY : STD_LOGIC_VECTOR(0 DOWNTO 0);
    SIGNAL HEX5, HEX4, HEX3, HEX2, HEX1, HEX0 : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
    CONSTANT clock_period : time := 20 ns;
    
BEGIN
    clock_process: PROCESS
    BEGIN
        CLOCK_50 <= '0';
        WAIT FOR clock_period / 2;
        CLOCK_50 <= '1';
        WAIT FOR clock_period / 2;
    END PROCESS;

    KEY_process: PROCESS
    BEGIN
        KEY <= "0";
        WAIT FOR 20 ns;             -- perform reset
        KEY <= "1";
        WAIT;
    END PROCESS;

    SW_process: PROCESS
    BEGIN
        SW <= "0000000000";
        WAIT FOR 40 ns;
        SW <= "1000000001";
        WAIT;
    END PROCESS;

    U1: part8 PORT MAP (KEY, SW, CLOCK_50, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR);
END;
