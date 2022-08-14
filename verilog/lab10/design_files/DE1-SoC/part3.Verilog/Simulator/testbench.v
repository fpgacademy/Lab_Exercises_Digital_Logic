`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;

	reg [9:0] SW;
	wire [0:0] KEY;
	wire [9:0] LEDR;

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
		#20 SW	<= 10'b1010101010;
		#560 SW	<= 10'b1101010101;
	end // initial

	assign KEY[0] = Resetn;
	part3 U1 (KEY, SW, CLOCK_50, LEDR);

endmodule
