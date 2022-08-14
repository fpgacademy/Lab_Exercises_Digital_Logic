-- Reset with KEY[0]. SW[9] is Run.
-- The processor executes the instructions in the file inst_mem.mif
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY part3 IS 
    PORT ( KEY      : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
           SW       : IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
           CLOCK_50 : IN  STD_LOGIC;
           LEDR     : OUT STD_LOGIC_VECTOR(9 DOWNTO 0) );
END part3;

ARCHITECTURE Behavior OF part3 IS
    COMPONENT proc
        PORT ( DIN                 : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
               Resetn, Clock, Run  : IN  STD_LOGIC;
               DOUT                : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
               ADDR                : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
               W                   : OUT STD_LOGIC);
    END COMPONENT;
    COMPONENT inst_mem 
        PORT ( address  : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
               clock    : IN  STD_LOGIC ;
               data     : IN  STD_LOGIC_VECTOR (15 DOWNTO 0);
               wren     : IN  STD_LOGIC  := '1';
               q        : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
    END COMPONENT;
    COMPONENT regn
        GENERIC ( n : INTEGER := 16);
        PORT ( R                   : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
               Resetn, E, Clock    : IN STD_LOGIC;
               Q                   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    END COMPONENT;
    COMPONENT flipflop 
        PORT ( D, Resetn, Clock  : IN   STD_LOGIC;
               Q                 : OUT  STD_LOGIC);
    END COMPONENT;
    SIGNAL DOUT, ADDR : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL Sync, Run, High, inst_mem_cs, SW_cs, LED_reg_cs : STD_LOGIC;
    SIGNAL W, W_mem, W_LED : STD_LOGIC;
    SIGNAL DIN, inst_mem_q : STD_LOGIC_VECTOR(15 DOWNTO 0); 
    SIGNAL LED_reg, SW_reg : STD_LOGIC_VECTOR(8 DOWNTO 0); 
BEGIN
    High <= '1';
    -- synchronize the Run input
    U1: flipflop PORT MAP (SW(9), KEY(0), CLOCK_50, Sync);
    U2: flipflop PORT MAP (Sync, KEY(0), CLOCK_50, Run);
    
    -- proc(DIN, Resetn, Clock, Run, DOUT, ADDR, W);
    U3: proc PORT MAP (DIN, KEY(0), CLOCK_50, Run, DOUT, ADDR, W);

    inst_mem_cs <= '1' WHEN (ADDR(15 DOWNTO 12) = "0000") ELSE '0';
    LED_reg_cs <= '1' WHEN (ADDR(15 DOWNTO 12) = "0001") ELSE '0';
    SW_cs <= '1' WHEN (ADDR(15 DOWNTO 12) = "0011") ELSE '0';

    W_mem <= inst_mem_cs AND W;
    -- inst_mem ( address, clock, data, wren, q);
    U4: inst_mem PORT MAP (ADDR(7 DOWNTO 0), CLOCK_50, DOUT, W_mem, inst_mem_q);

    multiplexer: PROCESS (inst_mem_cs, SW_cs, inst_mem_q, SW_reg)
    BEGIN
        IF inst_mem_cs = '1' THEN
            DIN <= inst_mem_q;
        ELSIF SW_cs = '1' THEN
            DIN <= "0000000" & SW_reg;
        ELSE
            DIN <= (OTHERS => '-');
        END IF;
    END PROCESS;

    W_LED <= LED_reg_cs AND W;
    -- regn(R, E, Clock, Q);
    U5: regn GENERIC MAP (n => 9) 
             PORT MAP (DOUT(8 DOWNTO 0), KEY(0), W_LED, CLOCK_50, LED_reg);
    LEDR(8 DOWNTO 0) <= LED_reg;
    LEDR(9) <= Run;
    U6: regn GENERIC MAP (n => 9) 
             PORT MAP (SW(8 DOWNTO 0), KEY(0), High, CLOCK_50, SW_reg); -- SW(9) is used for Run
END Behavior;
