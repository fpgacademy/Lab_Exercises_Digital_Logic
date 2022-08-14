-- Data written to registers R0 to R5 are sent to the H digits
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY seg7 IS
    PORT ( Data                   : IN   STD_LOGIC_VECTOR(6 DOWNTO 0);
           Addr                   : IN   STD_LOGIC_VECTOR(2 DOWNTO 0);
           Sel, Resetn, Clock     : IN   STD_LOGIC;
           H5, H4, H3, H2, H1, H0 : OUT  STD_LOGIC_VECTOR(6 DOWNTO 0) );
END seg7;

ARCHITECTURE Behavior OF seg7 IS
    COMPONENT regne
        GENERIC ( n : INTEGER := 7);
        PORT ( R                : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
               Clock, Resetn, E : IN  STD_LOGIC;
               Q                : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    END COMPONENT;

    SIGNAL nData : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL W : STD_LOGIC_VECTOR(5 DOWNTO 0);
BEGIN
    nData <= NOT Data;

    W(0) <= '1' WHEN (Sel = '1' AND (Addr = "000")) ELSE '0';
    W(1) <= '1' WHEN (Sel = '1' AND (Addr = "001")) ELSE '0';
    W(2) <= '1' WHEN (Sel = '1' AND (Addr = "010")) ELSE '0';
    W(3) <= '1' WHEN (Sel = '1' AND (Addr = "011")) ELSE '0';
    W(4) <= '1' WHEN (Sel = '1' AND (Addr = "100")) ELSE '0';
    W(5) <= '1' WHEN (Sel = '1' AND (Addr = "101")) ELSE '0';
    reg_R0: regne PORT MAP (nData, Clock, Resetn, W(0), H0);
    reg_R1: regne PORT MAP (nData, Clock, Resetn, W(1), H1);
    reg_R2: regne PORT MAP (nData, Clock, Resetn, W(2), H2);
    reg_R3: regne PORT MAP (nData, Clock, Resetn, W(3), H3);
    reg_R4: regne PORT MAP (nData, Clock, Resetn, W(4), H4);
    reg_R5: regne PORT MAP (nData, Clock, Resetn, W(5), H5);
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY regne IS
    GENERIC ( n : INTEGER := 7);
    PORT ( R                : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           Clock, Resetn, E : IN  STD_LOGIC;
           Q                : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regne;

ARCHITECTURE Behavior OF regne IS
BEGIN
    PROCESS (Clock)
    BEGIN
        IF Clock'EVENT AND Clock = '1' THEN
            IF Resetn = '0' THEN
                Q <= (OTHERS => '1');   -- turn OFF all segments
            ELSIF E = '1' THEN
                Q <= R;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
