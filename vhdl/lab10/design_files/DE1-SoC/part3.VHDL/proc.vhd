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
        PORT ( E   : IN   STD_LOGIC;
               W   : IN   STD_LOGIC_VECTOR(2 DOWNTO 0);
               Y   : OUT  STD_LOGIC_VECTOR(0 TO 7));
    END COMPONENT;
    COMPONENT regn
        GENERIC ( n : INTEGER := 16);
        PORT ( R                   : IN STD_LOGIC_VECTOR(n-1 DOWNTO 0);
               Resetn, E, Clock    : IN STD_LOGIC;
               Q                   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
    END COMPONENT;
    COMPONENT flipflop 
        PORT (  D, Resetn, Clock  : IN  STD_LOGIC;
                Q                 : OUT STD_LOGIC);
    END COMPONENT;
   
    TYPE State_type IS (T0, T1, T2, T3, T4, T5);
    SIGNAL Tstep_Q, Tstep_D: State_type;
    SIGNAL Sel : STD_LOGIC_VECTOR(3 DOWNTO 0); -- bus selector
    SIGNAL Rin : STD_LOGIC_VECTOR(0 TO 7); -- r0, ..., r7 register enables
    SIGNAL Sum : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL rXin, IRin, Done, ADDRin, DOUTin, Imm, Ain, Gin, AddSub, ALUand : STD_LOGIC;
    SIGNAL III, rX, rY : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL Xreg : STD_LOGIC_VECTOR(0 TO 7);
    SIGNAL r0, r1, r2, r3, r4, r5, r6, PC, A : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL G : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL IR, BusWires : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL pc_incr, W_D : STD_LOGIC;

    CONSTANT mv : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
    CONSTANT mvt : STD_LOGIC_VECTOR(2 DOWNTO 0) := "001";
    CONSTANT add : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
    CONSTANT sub : STD_LOGIC_VECTOR(2 DOWNTO 0) := "011";
    CONSTANT ld : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
    CONSTANT st : STD_LOGIC_VECTOR(2 DOWNTO 0) := "101";
    CONSTANT and_it : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
    -- selectors for the BusWires multiplexer
    CONSTANT SEL_R0 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
    CONSTANT SEL_R1 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0001";
    CONSTANT SEL_R2 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010";
    CONSTANT SEL_R3 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0011";
    CONSTANT SEL_R4 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0100";
    CONSTANT SEL_R5 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0101";
    CONSTANT SEL_R6 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0110";
    CONSTANT SEL_PC : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0111";
    CONSTANT SEL_G : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1000";
    CONSTANT SEL_IR8_IR8_0 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1001"; -- sign-extended #D
    CONSTANT SEL_IR7_0_0 : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1010" ;  -- #D << 8
    CONSTANT SEL_DIN : STD_LOGIC_VECTOR(3 DOWNTO 0) := "1011" ;  -- data in
BEGIN
    III <= IR(15 DOWNTO 13);
    Imm <= IR(12);
    rX <= IR(11 DOWNTO 9);
    rY <= IR(2 DOWNTO 0);
    decX: dec3to8 PORT MAP (rXin, rX, Rin); -- produce r0 - r7 register enables

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

    controlsignals: PROCESS (Tstep_Q, III, Imm, rX, rY, Run)
    BEGIN
        -- default assignments
        rXin <= '0'; Ain <= '0'; Gin <= '0'; AddSub <= '0'; IRin <= '0'; Sel <= "----";
        ADDRin <= '0'; DOUTin <= '0'; W_D <= '0'; ALUand <= '0'; Done <= '0';
        pc_incr <= '0';
        CASE Tstep_Q IS
            WHEN T0 =>
                Sel <= SEL_PC;  -- put PC onto the internal bus
                ADDRin <= '1';
                pc_incr <= Run; -- increment PC
            WHEN T1 =>          -- wait cycle for synchronous memory
                null;
            WHEN T2 => -- store instruction on DIN into IR
                IRin <= '1';
            WHEN T3 => -- define signals in time step T1
                CASE III IS
                    WHEN mv =>
                        IF Imm = '0' THEN Sel <= '0' & rY;  -- mv rX, rY
                        ELSE Sel <= SEL_IR8_IR8_0;          -- mv rX, #D
                        END IF;
                        rXin <= '1';                        -- enable rX register
                        Done <= '1';
                    WHEN mvt =>
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
   
    reg_0:  regn PORT MAP (BusWires, Resetn, Rin(0), Clock, r0);
    reg_1:  regn PORT MAP (BusWires, Resetn, Rin(1), Clock, r1);
    reg_2:  regn PORT MAP (BusWires, Resetn, Rin(2), Clock, r2);
    reg_3:  regn PORT MAP (BusWires, Resetn, Rin(3), Clock, r3);
    reg_4:  regn PORT MAP (BusWires, Resetn, Rin(4), Clock, r4);
    reg_5:  regn PORT MAP (BusWires, Resetn, Rin(5), Clock, r5);
    reg_6:  regn PORT MAP (BusWires, Resetn, Rin(6), Clock, r6);

    -- pc_count(R, Resetn, Clock, E, L, Q);
    Upc: pc_count PORT MAP (BusWires, Resetn, Clock, pc_incr, Rin(7), PC);

    reg_A:  regn PORT MAP (BusWires, Resetn, Ain, Clock, A);
    reg_ADDR: regn PORT MAP (BusWires, Resetn, ADDRin, Clock, ADDR);
    reg_DOUT: regn PORT MAP (BusWires, Resetn, DOUTin, Clock, DOUT);
    reg_IR: regn PORT MAP (DIN, Resetn, IRin, Clock, IR);

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

    reg_G: regn PORT MAP (Sum, Resetn, Gin, Clock, G);

    busmux: PROCESS (Sel, r0, r1, r2, r3, r4, r5, r6, PC, G, IR, DIN)
    BEGIN
        CASE Sel IS
            WHEN SEL_R0 => BusWires <= r0;
            WHEN SEL_R1 => BusWires <= r1;
            WHEN SEL_R2 => BusWires <= r2;
            WHEN SEL_R3 => BusWires <= r3;
            WHEN SEL_R4 => BusWires <= r4;
            WHEN SEL_R5 => BusWires <= r5;
            WHEN SEL_R6 => BusWires <= r6;
            WHEN SEL_PC => BusWires <= PC;
            WHEN SEL_G => BusWires <= G;
            WHEN SEL_IR8_IR8_0 => BusWires <= (15 DOWNTO 9 => IR(8)) & IR(8 DOWNTO 0);
            WHEN SEL_IR7_0_0 => BusWires <= IR(7 DOWNTO 0) & "00000000";
            WHEN SEL_DIN => BusWires <= DIN;
            WHEN OTHERS => BusWires <= (OTHERS => '0');
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
    PORT ( E   : IN   STD_LOGIC;
           W   : IN   STD_LOGIC_VECTOR(2 DOWNTO 0);
           Y   : OUT  STD_LOGIC_VECTOR(0 TO 7));
END dec3to8;

ARCHITECTURE Behavior OF dec3to8 IS
BEGIN
    PROCESS (E, W)
    BEGIN
        IF E = '0'THEN
            Y <= "00000000";
        ELSE
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
        END IF;
    END PROCESS;
END Behavior;

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY regn IS
    GENERIC ( n : INTEGER := 16);
    PORT ( R                   : IN  STD_LOGIC_VECTOR(n-1 DOWNTO 0);
           Resetn, E, Clock    : IN  STD_LOGIC;
           Q                   : OUT STD_LOGIC_VECTOR(n-1 DOWNTO 0));
END regn;

ARCHITECTURE Behavior OF regn IS
BEGIN
    PROCESS (Clock)
    BEGIN
        IF Clock'EVENT AND Clock = '1' THEN
            IF Resetn = '0' THEN
                Q <= (OTHERS => '0');
            ELSIF E = '1' THEN
                Q <= R;
            END IF;
        END IF;
    END PROCESS;
END Behavior;
