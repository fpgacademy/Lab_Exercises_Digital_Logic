`timescale 1ns / 1ps

module testbench ( );

	reg [9:0] SW;
	reg [1:0] KEY;
	wire [9:0] LEDR;

	initial begin
		SW[9] <= 1'b1; SW[0] <= 1'b0;
		#20 SW[0] <= 1'b1;
	end // initial

	initial begin
		KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1; KEY[1] <= 1'b1;		// MClock, PClock
		#10 KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1;							// MClock
		#10 KEY[0] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1; KEY[1] <= 1'b1;		// MClock, PClock
		#10 KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1; KEY[1] <= 1'b1;		// MClock, PClock
		#10 KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1; KEY[1] <= 1'b1;		// MClock, PClock
		#10 KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1; KEY[1] <= 1'b1;		// MClock, PClock
		#10 KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[0] <= 1'b1; KEY[1] <= 1'b1;		// MClock, PClock
		#10 KEY[0] <= 1'b0; KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
		#10 KEY[1] <= 1'b1;							// PClock
		#10 KEY[1] <= 1'b0;
	end // initial

	part2 U1 (KEY, SW, LEDR);

endmodule
