LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY Top IS
    PORT (
        CLOCK_50  : IN    STD_LOGIC;                      -- DE-series 50 MHz clock signal
        KEY       : IN    STD_LOGIC_VECTOR( 3 DOWNTO 0);  -- DE-series pushbuttons
        SW        : IN    STD_LOGIC_VECTOR( 9 DOWNTO 0);  -- DE-series switches
        HEX0      : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);  -- DE-series HEX displays 
        HEX1      : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
        HEX2      : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
        HEX3      : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
        HEX4      : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
        HEX5      : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
        LEDR      : OUT   STD_LOGIC_VECTOR( 9 DOWNTO 0)   -- DE-series LEDs 
    );
END Top;

ARCHITECTURE Behavior OF Top IS
    COMPONENT part2
        PORT ( 
            KEY    : IN    STD_LOGIC_VECTOR( 1 DOWNTO 0);
            SW     : IN    STD_LOGIC_VECTOR( 9 DOWNTO 0);
            LEDR   : OUT   STD_LOGIC_VECTOR( 9 DOWNTO 0)
        );
    END COMPONENT;
BEGIN

    U1: part2 PORT MAP (KEY(1 DOWNTO 0), SW, LEDR);
    HEX0 <= "1111111";
    HEX1 <= "1111111";
    HEX2 <= "1111111";
    HEX3 <= "1111111";
    HEX4 <= "1111111";
    HEX5 <= "1111111";

END Behavior;


