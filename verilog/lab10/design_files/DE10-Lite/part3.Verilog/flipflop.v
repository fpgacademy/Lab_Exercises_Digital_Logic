module flipflop (D, Resetn, Clock, Q);
	input D, Resetn, Clock;
	output Q;
	reg Q;	
	
	always @(posedge Clock)
		if (Resetn == 0)
			Q <= 1'b0;
		else
			Q <= D;
endmodule
