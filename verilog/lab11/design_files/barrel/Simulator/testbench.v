`timescale 1ns / 1ps

module testbench ( );
	reg [1:0] shift_type;
	reg [15:0] data_in;
	wire [15:0] data_out;
	reg [3:0] shift;

    parameter lsl = 2'b00, lsr = 2'b01, asr = 2'b10, ror = 2'b11;

    barrel U1 (shift_type, shift, data_in, data_out);

	initial begin
		shift_type <= lsl; data_in <= 16'hF0F0; shift <= 4'b0;
		#20 shift <= 4'b1;
		#20 shift_type <= lsr;
		#20 shift_type = lsl; shift <= 4'b0100;
		#20 shift_type <= lsr;
		#20 shift_type <= asr; shift <= 4'b0;
		#20 shift <= 4'b0100;
		#20 shift_type <= ror; shift <= 4'b0;
		#20 shift <= 4'b0100;
		#20 shift <= 4'b1000;
		#20 shift_type <= asr; data_in <= 16'h8080; shift <= 4'b0;
		#20 shift <= 4'b1;
		#20 shift <= 4'b0100;
		#20 shift_type = ror; shift <= 4'b1;
		#20 shift_type = ror; shift <= 4'b0100;
		#20 shift_type = ror; shift <= 4'b1111;
	end // initial

endmodule
