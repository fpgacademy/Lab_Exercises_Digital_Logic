library ieee;
use ieee.std_logic_1164.all;


entity testbench is
end testbench;

architecture tb of testbench is
	constant T_clk : time := 60 ns;
	signal clk_tb, D_tb : std_logic;  -- inputs 
	signal Qa_tb, Qb_tb, Qc_tb : std_logic;  -- outputs
begin
	-- connecting testbench signals
	UUT : entity work.part4 port map ( Clk => clk_tb, D => D_tb, Qa => Qa_tb, Qb => Qb_tb, Qc => Qc_tb );

	-- continuous clock
	
	process
	begin
	clk_tb <= '0';
	wait for T_clk/2;
	clk_tb <= '1';
	wait for T_clk/2;
	end process;

	-- signals
	process
	begin
	D_tb <= '0';
	wait for 20 ns;
	D_tb <= '1';
	wait for 20 ns;
	D_tb <= '0';
	wait for 5 ns;
	D_tb <= '1';
	wait for 10 ns;
	D_tb <= '0';
	wait for 10 ns;
	D_tb <= '1';
	wait for 10 ns;
	D_tb <= '0';
	wait for 5 ns;
	D_tb <= '1';
	wait for 5 ns;
	D_tb <= '0';
	wait for 10 ns;
	D_tb <= '1';
	wait for 5 ns;
	D_tb <= '0';
	wait for 5 ns;
	D_tb <= '1';
	wait for 20 ns;
	D_tb <= '0';
	wait for 50 ns;
	end process;
end tb ;