.define HEX_ADDRESS 0x2000

// This program shows ECE243 on the 7-seg displays

MAIN:		mvt	r2, #HEX_ADDRESS	// point to HEX port
			mv 	r3, #DATA			// used to get 7-segment display pattern
			ld		r0, [r3]				// load the 7-segment pattern
			st		r0, [r2]				// light up HEX display
			add	r2, #1				// point to the next HEX display
			add	r3, #1				// point to the next 7-segment pattern
			ld		r0, [r3]				// load the 7-segment pattern
			st		r0, [r2]				// light up HEX display
			add	r2, #1				// point to the next HEX display
			add	r3, #1				// point to the next 7-segment pattern
			ld		r0, [r3]				// load the 7-segment pattern
			st		r0, [r2]				// light up HEX display
			add	r2, #1				// point to the next HEX display
			add	r3, #1				// point to the next 7-segment pattern
			ld		r0, [r3]				// load the 7-segment pattern
			st		r0, [r2]				// light up HEX display
			add	r2, #1				// point to the next HEX display
			add	r3, #1				// point to the next 7-segment pattern
			ld		r0, [r3]				// load the 7-segment pattern
			st		r0, [r2]				// light up HEX display
			add	r2, #1				// point to the next HEX display
			add	r3, #1				// point to the next 7-segment pattern
			ld		r0, [r3]				// load the 7-segment pattern
			st		r0, [r2]				// light up HEX display

END:		mv 	pc, #END

DATA:		.word 0b01001111	      // '3'
			.word 0b01100110	      // '4'
      	.word 0b01011011	      // '2'
			.word	0b01111001	      // 'E'
			.word	0b00111001	      // 'C'
			.word	0b01111001	      // 'E'
