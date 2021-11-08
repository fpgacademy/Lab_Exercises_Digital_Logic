LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE Behavior OF testbench IS
    COMPONENT part2
        PORT (  KEY   : IN   STD_LOGIC_VECTOR(1 DOWNTO 0);
                SW    : IN   STD_LOGIC_VECTOR(9 DOWNTO 0);
                LEDR  : OUT  STD_LOGIC_VECTOR(9 DOWNTO 0));
    END COMPONENT;

    SIGNAL SW : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL KEY : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL LEDR : STD_LOGIC_VECTOR(9 DOWNTO 0);
BEGIN
    U1: part2 PORT MAP (KEY, SW, LEDR);

    SW_process: PROCESS
    BEGIN
        SW(9) <= '1'; SW(0) <= '0'; -- Run = 1, Resetn = 0
        WAIT FOR 20 ns;             -- Resetn = 1
        SW(0) <= '1';
        WAIT;
    END PROCESS;

    vectors: PROCESS
    BEGIN
        KEY(0) <= '0'; KEY(1) <= '0';   -- KEY(0) is MClock, KEY(1) is PClock
        WAIT FOR 10 ns; KEY(0) <= '1'; KEY(1) <= '1';		-- MClock, PClock
        WAIT FOR 10 ns; KEY(0) <= '0'; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(0) <= '1';							-- MClock
        WAIT FOR 10 ns; KEY(0) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(0) <= '1'; KEY(1) <= '1';		-- MClock, PClock
        WAIT FOR 10 ns; KEY(0) <= '0'; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(0) <= '1'; KEY(1) <= '1';		-- MClock, PClock
        WAIT FOR 10 ns; KEY(0) <= '0'; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(0) <= '1'; KEY(1) <= '1';		-- MClock, PClock
        WAIT FOR 10 ns; KEY(0) <= '0'; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(0) <= '1'; KEY(1) <= '1';		-- MClock, PClock
        WAIT FOR 10 ns; KEY(0) <= '0'; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(0) <= '1'; KEY(1) <= '1';		-- MClock, PClock
        WAIT FOR 10 ns; KEY(0) <= '0'; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns; KEY(1) <= '0';
        WAIT FOR 10 ns; KEY(1) <= '1';							-- PClock
        WAIT FOR 10 ns;
        KEY(1) <= '0';
        WAIT;
    END PROCESS;
END;
