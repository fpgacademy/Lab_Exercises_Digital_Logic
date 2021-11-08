`timescale 1ns / 1ns

module testbench ();
	reg Clk_tb;
	reg R_tb;
	reg S_tb;
	wire Q_tb;
	
	initial
		begin: CLOCK_GENERATOR
			Clk_tb = 1;
			forever
				begin
					#5 Clk_tb = ~Clk_tb;
				end
		end
	
	initial
		begin
			R_tb <= 1; S_tb <= 0;
			#20 R_tb <= 0; 
			#20 S_tb <= 1;
			#20 S_tb <= 0;
			#20 R_tb <= 1;
		end
		
	part1 p1 (Clk_tb, R_tb, S_tb, Q_tb);
endmodule