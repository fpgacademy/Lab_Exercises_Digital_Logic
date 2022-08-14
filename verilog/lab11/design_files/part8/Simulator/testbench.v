`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;

	reg [9:0] SW;
	wire [0:0] KEY;
	wire [9:0] LEDR;
	wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;

	reg CLOCK_50;
	initial begin
		CLOCK_50 <= 1'b0;
	end // initial
	always @ (*)
	begin : Clock_Generator
		#((CLOCK_PERIOD) / 2) CLOCK_50 <= ~CLOCK_50;
	end
	
	reg Resetn;
	initial begin
		Resetn <= 1'b0;
		#20 Resetn <= 1'b1;
	end // initial

	initial begin
		SW <= 10'h0;
		#40 SW	<= 10'b1000000011;
	end // initial

	assign KEY[0] = Resetn;
	part8 U1 (KEY, SW, CLOCK_50, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0, LEDR);

endmodule
