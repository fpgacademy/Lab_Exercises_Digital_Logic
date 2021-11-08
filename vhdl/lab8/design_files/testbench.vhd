library ieee;
use ieee.std_logic_1164.all;


entity testbench is
end testbench;

architecture tb of testbench is
	constant T_clk : time := 10 ns;
	signal clk_tb, wren_tb : std_logic;  -- inputs 
	signal addr_tb : std_logic_vector(4 downto 0);
	signal din_tb : std_logic_vector(3 downto 0);
	signal dout_tb : std_logic_vector(3 downto 0);  -- outputs
begin
	-- connecting testbench signals
	UUT : entity work.part1 port map ( Clock => clk_tb, Write => wren_tb, DataIn => din_tb, Address => addr_tb, DataOut => dout_tb );

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
	addr_tb <= "00000"; din_tb <= "0000"; wren_tb <= '0';
	wait for 20 ns;
	din_tb <= "1010"; wren_tb <= '1';
	wait for 10 ns;
	din_tb <= "0000"; wren_tb <= '0';
	wait for 10 ns;
	addr_tb <= "11111"; din_tb <= "0101"; wren_tb <= '1';
	wait for 10 ns;
	addr_tb <= "00000"; din_tb <= "0000"; wren_tb <= '0';
	wait for 10 ns;
	addr_tb <= "11111";
	wait for 50 ns;
	end process;
end tb ;