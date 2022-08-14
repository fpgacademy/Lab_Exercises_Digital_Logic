-- This top-level file shows you how to instantiate the barrel shift Verilog module
-- in your processor VHDL code. In this example, shift_type would be extracted from
-- the machine code of the shift instruction currently being executed in the processor.
-- It would be either 00 (lsl), 01 (lsr), 10 (asr), or 11 (ror). The signal A represents
-- the content of register A in the ALU (the first operand of a shift instruction). The
-- signal BusWires represents Op2 of the shift instruction (which would be on the 
-- processor's BusWires(3 DOWNTO 0). Finally, B represents the output of the barrel
-- shifter, which would be the output of your ALU (that gets loaded into register G)
-- when executing a shift instruction.

-- Note: the testbench.tcl script for this example, in the Simulator folder, compiles
-- both the VHDL and Verilog code included in this example.

LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY top IS 
    PORT ( shift_type   : IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
           A            : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
           BusWires     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
           B            : OUT STD_LOGIC_VECTOR(16 DOWNTO 0) );
END top;

ARCHITECTURE Behavior OF top IS
    COMPONENT barrel
        PORT ( shift_type : IN   STD_LOGIC_VECTOR(1 DOWNTO 0);
               shift      : IN   STD_LOGIC_VECTOR(3 DOWNTO 0);
               data_in    : IN   STD_LOGIC_VECTOR(15 DOWNTO 0);
               data_out   : OUT  STD_LOGIC_VECTOR(16 DOWNTO 0));
    END COMPONENT;
BEGIN

    ALUshift: barrel PORT MAP (shift_type, BusWires(3 DOWNTO 0), A, B); 

END Behavior;
