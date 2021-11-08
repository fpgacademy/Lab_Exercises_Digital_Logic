library ieee;
use ieee.std_logic_1164.all;


entity testbench is
end testbench;

architecture tb of testbench is
	constant T_clk : time := 20 ns;
	signal clk_tb, r_tb, s_tb : std_logic;  -- inputs 
	signal q_tb : std_logic;  -- outputs
begin
	-- connecting testbench signals
	UUT : entity work.part1 port map ( Clk => clk_tb, R => r_tb, s => S_tb, Q => q_tb );

	-- continuous clock
	
	process
	begin
	clk_tb <= '1';
	wait for T_clk/2;
	clk_tb <= '0';
	wait for T_clk/2;
	end process;

	-- signals
	process
	begin
	r_tb <= '1'; s_tb <= '0';
	wait for 10 ns;
	r_tb <= '0';
	wait for 20 ns;
	s_tb <= '1';
	wait for 20 ns;
	s_tb <= '0';
	wait for 20 ns;
	r_tb <= '1';
	wait for 20 ns;
	r_tb <= '0';
	wait for 60 ns;
	end process;
end tb ;