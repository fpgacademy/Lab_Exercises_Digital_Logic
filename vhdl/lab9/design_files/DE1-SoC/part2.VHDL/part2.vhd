-- Reset with SW(0). Clock counter and memory with KEY(0). Clock
-- each instuction into the processor with KEY(1). SW(9) is the Run input.
-- Use KEY(0) to advance the memory as needed before each processor KEY(1)
-- clock cycle.
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY part2 IS 
    PORT ( KEY   : IN   STD_LOGIC_VECTOR(1 DOWNTO 0);
           SW    : IN   STD_LOGIC_VECTOR(9 DOWNTO 0);
           LEDR  : OUT  STD_LOGIC_VECTOR(9 DOWNTO 0));
END part2;

ARCHITECTURE Behavior OF part2 IS
   COMPONENT proc
      PORT ( DIN                 : IN      STD_LOGIC_VECTOR(15 DOWNTO 0);
             Resetn, Clock, Run  : IN      STD_LOGIC;
             Done                : BUFFER  STD_LOGIC);
   END COMPONENT;
   COMPONENT inst_mem 
      PORT ( address   : IN STD_LOGIC_VECTOR (4 DOWNTO 0);
             clock     : IN STD_LOGIC ;
             q         : OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
   END COMPONENT;
   COMPONENT count5
      PORT ( Resetn, Clock   : IN   STD_LOGIC;
             Q               : OUT  STD_LOGIC_VECTOR(4 DOWNTO 0));
   END COMPONENT;

   SIGNAL Resetn, PClock, MClock, Run, Done : STD_LOGIC;
   SIGNAL DIN : STD_LOGIC_VECTOR(15 DOWNTO 0); 
   SIGNAL pc : STD_LOGIC_VECTOR(4 DOWNTO 0); 
BEGIN
   Resetn <= SW(0);
   MClock <= KEY(0);
   PClock <= KEY(1);
   Run <= SW(9);
   U1: proc PORT MAP (DIN, Resetn, PClock, Run, Done);
   LEDR(0) <= Done;
   LEDR(9) <= Run;

   U2: inst_mem PORT MAP (pc, MClock, DIN);
   U3: count5 PORT MAP (Resetn, MClock, pc);
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY count5 IS 
    PORT ( Resetn, Clock   : IN   STD_LOGIC;
           Q               : OUT  STD_LOGIC_VECTOR(4 DOWNTO 0));
END count5;

ARCHITECTURE Behavior OF count5 IS
   SIGNAL Count : STD_LOGIC_VECTOR(4 DOWNTO 0); 
BEGIN
   PROCESS (Clock, Resetn)
   BEGIN
         IF (Resetn = '0') THEN
            Count <= "00000";
         ELSIF (rising_edge(Clock)) THEN
            Count <= Count + '1';
         END IF;
   END PROCESS;
   Q <= Count;
END Behavior;
