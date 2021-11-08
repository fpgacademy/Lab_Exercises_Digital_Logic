// Data written to registers R0 to R5 are sent to the H digits
module seg7 (Data, Addr, Sel, Resetn, Clock, H5, H4, H3, H2, H1, H0);
    input [6:0] Data;
    input [2:0] Addr;
    input Sel, Resetn, Clock;
    output [6:0] H5, H4, H3, H2, H1, H0;

    wire [6:0] nData;
    assign nData = ~Data;

    regne reg_R0 (nData, Clock, Resetn, Sel & (Addr == 3'b000), H0);
	 // ... add code here
endmodule

module regne (R, Clock, Resetn, E, Q);
    parameter n = 7;
    input [n-1:0] R;
    input Clock, Resetn, E;
    output [n-1:0] Q;
    reg [n-1:0] Q;	
	
    always @(posedge Clock)
        if (Resetn == 0)
            Q <= {n{1'b1}};  // turn OFF all segments on reset
        else if (E)
            Q <= R;
endmodule
