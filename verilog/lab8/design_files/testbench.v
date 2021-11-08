`timescale 1ns / 1ns

module testbench ();
	reg [4:0] addr_tb;
	reg clock_tb;
	reg [3:0] din_tb;
	reg wren_tb;
	wire [3:0] dout_tb;
	
	initial
		begin: CLOCK_GENERATOR
			clock_tb = 0;
			forever
				begin
					#5 clock_tb = ~clock_tb;
				end
		end
	
	initial
		begin
			addr_tb <= 5'b00000; din_tb <= 4'b0000; wren_tb <= 0;
			#20 din_tb <= 4'b1010; wren_tb <= 1;
			#10 din_tb <= 4'b0000; wren_tb <= 0;
			#10 addr_tb <= 5'b11111; din_tb <= 4'b0101; wren_tb <= 1;
			#10 addr_tb <= 5'b00000; din_tb <= 4'b0000; wren_tb <= 0;
			#10 addr_tb <= 5'b11111;
		end
		
	ram32x4 ram (addr_tb, clock_tb, din_tb, wren_tb, dout_tb);
endmodule