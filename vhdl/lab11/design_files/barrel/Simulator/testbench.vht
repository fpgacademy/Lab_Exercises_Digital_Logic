LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE Behavior OF testbench IS
    COMPONENT top
       PORT ( shift_type   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
              A            : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
              BusWires     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
              B            : OUT STD_LOGIC_VECTOR(16 DOWNTO 0) );
    END COMPONENT;

    SIGNAL shift_type : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL A : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL BusWires : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL B : STD_LOGIC_VECTOR (16 DOWNTO 0);
    -- shift types
    CONSTANT lsl : STD_LOGIC_VECTOR(1 DOWNTO 0) := "00";
    CONSTANT lsr : STD_LOGIC_VECTOR(1 DOWNTO 0) := "01";
    CONSTANT asr : STD_LOGIC_VECTOR(1 DOWNTO 0) := "10";
    CONSTANT rotate : STD_LOGIC_VECTOR(1 DOWNTO 0) := "11";
    
BEGIN
    main_process: PROCESS
    BEGIN
        shift_type <= lsl; A <= "1111000011110000"; BusWires <= "0000";
        WAIT FOR 20 ns;
        BusWires <= "0001";
        WAIT FOR 20 ns;
        shift_type <= lsr; 
        WAIT FOR 20 ns;
        shift_type <= lsr; BusWires <= "0100";
        WAIT FOR 20 ns;
        shift_type <= lsr;
        WAIT FOR 20 ns;
        shift_type <= asr; BusWires <= "0000";
        WAIT FOR 20 ns;
        BusWires <= "0100";
        WAIT FOR 20 ns;
        shift_type <= rotate; BusWires <= "0000";
        WAIT FOR 20 ns;
        BusWires <= "0100";
        WAIT FOR 20 ns;
        BusWires <= "1000";
        WAIT FOR 20 ns;
        WAIT;
    END PROCESS;

    U1: top PORT MAP (shift_type, A, BusWires, B);
END;
