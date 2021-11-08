library ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY proc IS
    PORT (  DIN                 : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
            Resetn, Clock, Run  : IN  STD_LOGIC;
            DOUT                : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            ADDR                : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
            W                   : OUT STD_LOGIC);
END proc;
   
ARCHITECTURE Behavior OF proc IS
    COMPONENT pc_count
        PORT (  R    : IN   STD_LOGIC_VECTOR(15 DOWNTO 0);
                Resetn, Clock, E, L   : IN   STD_LOGIC;
                Q    : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
    END COMPONENT;
    COMPONENT dec3to8
        PORT ( W   : IN   STD_LOGIC_VECTOR(2 DOWNTO 0);
               Y   : OUT  STD_LOGIC_VECTOR(0 TO 7));
    END COMPONENT;

    COMPONENT regn
        GENERIC ( n : INTEGER := 16);
        PORT ( R           : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
               Rin, Clock  : IN STD_LOGIC;
               Q           : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    END COMPONENT;
    COMPONENT flipflop 
        PORT (  D, Resetn, Clock  : IN  STD_LOGIC;
                Q                 : OUT STD_LOGIC);
    END COMPONENT;
   
    TYPE State_type IS (T0, T1, T2, T3, T4, T5);
    SIGNAL Tstep_Q, Tstep_D: State_type;
    CONSTANT mv : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
    CONSTANT mvt : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
    CONSTANT add : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
    CONSTANT sub : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
    CONSTANT ld : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
    CONSTANT st : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
    CONSTANT and_it : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
    CONSTANT Sel_R0 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    CONSTANT Sel_R1 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT Sel_R2 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT Sel_R3 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
    CONSTANT Sel_R4 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    CONSTANT Sel_R5 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    CONSTANT Sel_R6 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    CONSTANT Sel_PC : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
    CONSTANT Sel_G : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
    CONSTANT Sel_D : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001";
    CONSTANT Sel_D8 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010";
             -- Sel_D is immediate data, Sel_D8 is immediate data << 8
    CONSTANT Sel_DIN : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1011";
    SIGNAL Sel : STD_LOGIC_VECTOR(3 DOWNTO 0); -- bus selector
    SIGNAL Rin : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL Sum : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IRin, Done, ADDRin, DOUTin, IMM, Ain, Gin, AddSub, ALUand : STD_LOGIC;
    SIGNAL III, rX, rY : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL Xreg : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL R0, R1, R2, R3, R4, R5, R6, PC, A, G : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IR, BusWires : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL pc_inc, W_D : STD_LOGIC;
BEGIN
    III <= IR(15 DOWNTO 13);
    IMM <= IR(12);
    rX <= IR(11 DOWNTO 9);
    rY <= IR(2 DOWNTO 0);
    decX: dec3to8 PORT MAP (rX, Xreg);
    
    statetable: PROCESS(Tstep_Q, Run, Done)
    BEGIN
        CASE Tstep_Q IS
            WHEN T0 =>    -- data is loaded into IR in this time step
                IF Run = '0' THEN Tstep_D <= T0;
                ELSE Tstep_D <= T1;
                END IF;
            WHEN T1 =>   -- some instructions end after this time step   
                Tstep_D <= T2;
            WHEN T2 =>   -- always go to T3 after this
                Tstep_D <= T3;
            WHEN T3 =>   -- some instructions end after this time step   
                IF Done = '1' THEN Tstep_D <= T0;
                ELSE Tstep_D <= T4;
                END IF;
            WHEN T4 =>   -- always go to T5 after this
                Tstep_D <= T5;
            WHEN T5 =>   -- always go to T3 after this
                Tstep_D <= T0;
        END CASE;
    END PROCESS;
    -- OPCODE format: III M XXX DDDDDDDDD, where 
    --    III = instruction, M = Immediate, XXX = rX. 
    --    If M = 0, DDDDDDDDD = 000000YYY = rY
    --    If M = 1, DDDDDDDDD = #D is the immediate operand 
    -- 
    -- III M  Instruction   Description
    -- --- -  -----------   -----------
    -- 000 0: mv   rX,rY    rX <- rY
    -- 000 1: mv   rX,#D    rX <- D (0 extended)
    -- 001 1: mvt  rX,#D    rX <- D << 8
    -- 010 0: add  rX,rY    rX <- rX + rY
    -- 010 1: add  rX,#D    rX <- rX + D
    -- 011 0: sub  rX,rY    rX <- rX - rY
    -- 011 1: sub  rX,#D    rX <- rX - D
    -- 100 0: ld   rX,[rY]  rX <- [rY]
    -- 101 0: st   rX,[rY]  [rY] <- rX
    -- 110 0: and  rX,rY    rX <- rX & rY
    -- 110 1: and  rX,#D    rX <- rX & D
    controlsignals: PROCESS (Tstep_Q, III, IMM, Xreg, rX, rY, Run)
    BEGIN
        Done <= '0'; Ain <= '0'; Gin <= '0'; AddSub <= '0'; -- default assignments
        IRin <= '0'; Rin <= "00000000"; Sel <= "----"; ADDRin <= '0'; DOUTin <= '0';
        W_D <= '0'; pc_inc <= '0'; ALUand <= '0';
        CASE Tstep_Q IS
            WHEN T0 =>
                Sel <= Sel_PC;  -- put PC onto the internal bus
                ADDRin <= '1';
                pc_inc <= Run;  -- increment PC
            WHEN T1 =>          -- wait cycle for synchronous memory
                null;
            WHEN T2 => -- store instruction on DIN into IR
                IRin <= '1';
            WHEN T3 => -- define signals in time step T1
                CASE III IS
                    WHEN mv =>
                        IF IMM = '0' THEN Sel <= '0' & rY;  -- mv rX, rY
                        ELSE Sel <= Sel_D;                  -- mv rX, #D
                        END IF;
                        Rin <= Xreg;
                        Done <= '1';
                    WHEN mvt =>                             -- mvt Rx, #D
                        -- ... your code goes here
                    WHEN add | sub | and_it =>
                        -- ... your code goes here
                    WHEN ld | st =>
                        -- ... your code goes here
                    WHEN OTHERS =>
                        null;
                END CASE;
            WHEN T4 => -- define signals in time step T2
                CASE III IS
                    WHEN add =>
                        -- ... your code goes here
                    WHEN sub =>
                        -- ... your code goes here
                    WHEN and_it =>
                        -- ... your code goes here
                    WHEN ld =>
                        null;   -- wait cycle for synchronous memory
                    WHEN st =>
                        -- ... your code goes here
                    WHEN OTHERS =>
                        null;
                END CASE;
            WHEN T5 => -- define signals in time step T3
                CASE III IS
                    WHEN add | sub | and_it =>
                        -- ... your code goes here
                    WHEN ld =>
                        -- ... your code goes here
                    WHEN st =>      -- wait cycle for synchronous memory
                        -- ... your code goes here
                    WHEN OTHERS =>
                        null;
                END CASE;
        END CASE;
    END PROCESS;

    fsmflipflops: PROCESS (Clock, Resetn, Tstep_D)
    BEGIN
        IF (Resetn = '0') THEN
            Tstep_Q <= T0;
        ELSIF (rising_edge(Clock)) THEN
            Tstep_Q <= Tstep_D;
        END IF;
    END PROCESS;   
   
    reg_0:  regn PORT MAP (BusWires, Rin(0), Clock, R0);
    reg_1:  regn PORT MAP (BusWires, Rin(1), Clock, R1);
    reg_2:  regn PORT MAP (BusWires, Rin(2), Clock, R2);
    reg_3:  regn PORT MAP (BusWires, Rin(3), Clock, R3);
    reg_4:  regn PORT MAP (BusWires, Rin(4), Clock, R4);
    reg_5:  regn PORT MAP (BusWires, Rin(5), Clock, R5);
    reg_6:  regn PORT MAP (BusWires, Rin(6), Clock, R6);

    -- pc_count(R, Resetn, Clock, E, L, Q);
    Upc: pc_count PORT MAP (BusWires, Resetn, Clock, pc_inc, Rin(7), PC);

    reg_A: regn PORT MAP (BusWires, Ain, Clock, A);
    reg_ADDR: regn PORT MAP (BusWires, ADDRin, Clock, ADDR);
    reg_DOUT: regn PORT MAP (BusWires, DOUTin, Clock, DOUT);
    reg_IR: regn PORT MAP (DIN, IRin, Clock, IR);

    reg_W: flipflop PORT MAP (W_D, Resetn, Clock, W);
    
    alu: PROCESS (AddSub, A, BusWires, ALUand)
    BEGIN
        IF ALUand = '0' THEN
            IF AddSub = '0' THEN
                Sum <= A + BusWires;
            ELSE
                Sum <= A - BusWires;
            END IF;
        ELSE
            Sum <= A AND BusWires;
        END IF;
    END PROCESS;

    reg_G: regn PORT MAP (Sum, Gin, Clock, G);

    busmux: PROCESS (Sel, R0, R1, R2, R3, R4, R5, R6, PC, G, IR, DIN)
    BEGIN
        CASE Sel IS
            WHEN Sel_R0 => BusWires <= R0;
            WHEN Sel_R1 => BusWires <= R1;
            WHEN Sel_R2 => BusWires <= R2;
            WHEN Sel_R3 => BusWires <= R3;
            WHEN Sel_R4 => BusWires <= R4;
            WHEN Sel_R5 => BusWires <= R5;
            WHEN Sel_R6 => BusWires <= R6;
            WHEN Sel_PC => BusWires <= PC;
            WHEN Sel_G => BusWires <= G;
            WHEN Sel_D => BusWires <= "0000000" & IR(8 DOWNTO 0);
            WHEN Sel_D8 => BusWires <= IR(7 DOWNTO 0) & "00000000";
            WHEN Sel_DIN => BusWires <= DIN;
            WHEN OTHERS => BusWires <= (OTHERS => '-');
        END CASE;
    END PROCESS;   
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY pc_count IS
   PORT ( R   : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
          Resetn, Clock, E, L  : IN  STD_LOGIC;
          Q   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0));
END pc_count;

ARCHITECTURE Behavior OF pc_count IS
   SIGNAL Count : STD_LOGIC_VECTOR(15 DOWNTO 0);
BEGIN
   PROCESS (Clock)
   BEGIN
      IF (Clock'EVENT AND Clock = '1') THEN
          IF (Resetn = '0') THEN
            Count <= (OTHERS => '0');
         ELSIF (L = '1') THEN 
            Count <= R;
         ELSIF (E = '1') THEN 
            Count <= Count + 1;
         END IF;
      END IF;
   END PROCESS;
   Q <= Count;
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY dec3to8 IS
    PORT ( W   : IN   STD_LOGIC_VECTOR(2 DOWNTO 0);
           Y   : OUT  STD_LOGIC_VECTOR(0 TO 7));
END dec3to8;

ARCHITECTURE Behavior OF dec3to8 IS
BEGIN
    PROCESS (W)
    BEGIN
        CASE W IS
            WHEN "000" => Y <= "10000000";
            WHEN "001" => Y <= "01000000";
            WHEN "010" => Y <= "00100000";
            WHEN "011" => Y <= "00010000";
            WHEN "100" => Y <= "00001000";
            WHEN "101" => Y <= "00000100";
            WHEN "110" => Y <= "00000010";
            WHEN "111" => Y <= "00000001";
            WHEN OTHERS => Y <= "00000000";
        END CASE;
    END PROCESS;
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY regn IS
    GENERIC ( n : INTEGER := 16);
    PORT ( R           : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           Rin, Clock  : IN  STD_LOGIC;
           Q           : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regn;

ARCHITECTURE Behavior OF regn IS
BEGIN
    PROCESS (Clock)
    BEGIN
        IF Clock'EVENT AND Clock = '1' THEN
            IF Rin = '1' THEN
                Q <= R;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
