`timescale 1ns / 1ps

module testbench ( );

	parameter CLOCK_PERIOD = 20;

	reg [15:0] Instruction;
	reg Run;
	wire Done;

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
				Run	<= 1'b0;	Instruction	<= 16'b0000000000000000;	
		#20	Run	<= 1'b1; Instruction	<= 16'b0001000000011100; // mv  r0, #28	
		#20	Run	<= 1'b0; 
		#20	Run	<= 1'b1; Instruction	<= 16'b0011001011111111; // mvt r1, #0xFF00
		#20	Run	<= 1'b0;
		#20	Run	<= 1'b1; Instruction	<= 16'b0101001011111111; // add r1, #0xFF
		#20	Run	<= 1'b0;
		#60	Run	<= 1'b1; Instruction	<= 16'b0110001000000000; // sub r1, r0
		#20	Run	<= 1'b0;
		#60	Run	<= 1'b1; Instruction	<= 16'b0101001000000001; // add r1, #1
		#20	Run	<= 1'b0;
	end // initial

	proc U1 (Instruction, Resetn, CLOCK_50, Run, Done);

endmodule
