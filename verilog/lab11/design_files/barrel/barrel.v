// This module specifies a barrel shifter that can perform lsl, lsr, asr, and ror
module barrel (shift_type, shift, data_in, data_out);
    input wire [1:0] shift_type;
    input wire [3:0] shift;
    input wire [15:0] data_in;
    output reg [15:0] data_out;

    parameter lsl = 2'b00, lsr = 2'b01, asr = 2'b10, ror = 2'b11;

    always @(*)
        if (shift_type == lsl)
            data_out = data_in << shift;
        else if (shift_type == lsr) 
            data_out = data_in >> shift;
        else if (shift_type == asr) 
            data_out = {{16{data_in[15]}},data_in} >> shift;    // sign extend
        else // ror
            data_out = (data_in >> shift) | (data_in << (16 - shift));
endmodule
