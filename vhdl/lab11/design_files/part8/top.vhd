LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY Top IS
    PORT (
        CLOCK_50  : IN    STD_LOGIC;                      -- DE-series 50 MHz clock signal
        SW        : IN    STD_LOGIC_VECTOR( 9 DOWNTO 0);  -- DE-series switches
        KEY       : IN    STD_LOGIC_VECTOR( 3 DOWNTO 0);  -- DE-series pushbuttons
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
    COMPONENT part8
        PORT ( 
            KEY      : IN    STD_LOGIC_VECTOR( 0 DOWNTO 0);
            SW       : IN    STD_LOGIC_VECTOR( 9 DOWNTO 0);
            CLOCK_50 : IN    STD_LOGIC;
            HEX0     : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
            HEX1     : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
            HEX2     : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
            HEX3     : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
            HEX4     : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
            HEX5     : OUT   STD_LOGIC_VECTOR( 6 DOWNTO 0);
            LEDR     : OUT   STD_LOGIC_VECTOR( 9 DOWNTO 0)
        );
    END COMPONENT;
BEGIN

    U1: part8 PORT MAP (KEY(0 DOWNTO 0), SW, CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, LEDR);

END Behavior;


