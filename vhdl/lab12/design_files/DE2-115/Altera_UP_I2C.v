/******************************************************************************
 * License Agreement                                                          *
 *                                                                            *
 * Copyright (c) 1991-2009 Altera Corporation, San Jose, California, USA.     *
 * All rights reserved.                                                       *
 *                                                                            *
 * Any megafunction design, and related net list (encrypted or decrypted),    *
 *  support information, device programming or simulation file, and any other *
 *  associated documentation or information provided by Altera or a partner   *
 *  under Altera's Megafunction Partnership Program may be used only to       *
 *  program PLD devices (but not masked PLD devices) from Altera.  Any other  *
 *  use of such megafunction design, net list, support information, device    *
 *  programming or simulation file, or any other related documentation or     *
 *  information is prohibited for any other purpose, including, but not       *
 *  limited to modification, reverse engineering, de-compiling, or use with   *
 *  any other silicon devices, unless such use is explicitly licensed under   *
 *  a separate agreement with Altera or a megafunction partner.  Title to     *
 *  the intellectual property, including patents, copyrights, trademarks,     *
 *  trade secrets, or maskworks, embodied in any such megafunction design,    *
 *  net list, support information, device programming or simulation file, or  *
 *  any other related documentation or information provided by Altera or a    *
 *  megafunction partner, remains with Altera, the megafunction partner, or   *
 *  their respective licensors.  No other licenses, including any licenses    *
 *  needed under any third party's intellectual property, are provided herein.*
 *  Copying or modifying any file, or portion thereof, to which this notice   *
 *  is attached violates this copyright.                                      *
 *                                                                            *
 * THIS FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    *
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   *
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    *
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER *
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    *
 * FROM, OUT OF OR IN CONNECTION WITH THIS FILE OR THE USE OR OTHER DEALINGS  *
 * IN THIS FILE.                                                              *
 *                                                                            *
 * This agreement shall be governed in all respects by the laws of the State  *
 *  of California and by the laws of the United States of America.            *
 *                                                                            *
 ******************************************************************************/

/******************************************************************************
 *                                                                            *
 * This module sends and receives data to/from the DE1's audio and TV         *
 *  peripherals' control registers.                                           *
 *                                                                            *
 ******************************************************************************/

module Altera_UP_I2C (
	// Inputs
	clk,
	reset,

	clear_ack,

	clk_400KHz,
	start_and_stop_en,
	change_output_bit_en,

	send_start_bit,
	send_stop_bit,

	data_in,
	transfer_data,
	read_byte,
	num_bits_to_transfer,

	// Bidirectionals
	i2c_sdata,

	// Outputs
	i2c_sclk,
	i2c_scen,

	enable_clk,

	ack,
	data_from_i2c,
	transfer_complete
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter I2C_BUS_MODE = 1'b0;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				clk;
input				reset;

input				clear_ack;

input				clk_400KHz;
input				start_and_stop_en;
input				change_output_bit_en;

input				send_start_bit;
input				send_stop_bit;

input		[7:0]	data_in;
input				transfer_data;
input				read_byte;
input		[2:0]	num_bits_to_transfer;

// Bidirectionals
inout				i2c_sdata;					//	I2C Data

// Outputs
output				i2c_sclk;					//	I2C Clock
output	reg			i2c_scen;

output				enable_clk;

output	reg			ack;
output	reg	[7:0]	data_from_i2c;
output				transfer_complete;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// states
localparam	I2C_STATE_0_IDLE			= 3'h0,
			I2C_STATE_1_PRE_START		= 3'h1,
			I2C_STATE_2_START_BIT		= 3'h2,
			I2C_STATE_3_TRANSFER_BYTE	= 3'h3,
			I2C_STATE_4_TRANSFER_ACK	= 3'h4,
			I2C_STATE_5_STOP_BIT		= 3'h5,
			I2C_STATE_6_COMPLETE		= 3'h6;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/
// Internal Wires

// Internal Registers
reg			[2:0]	current_bit;
reg			[7:0]	current_byte;

// State Machine Registers
reg			[2:0]	ns_i2c_transceiver;
reg			[2:0]	s_i2c_transceiver;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		s_i2c_transceiver <= I2C_STATE_0_IDLE;
	else
		s_i2c_transceiver <= ns_i2c_transceiver;
end

always @(*)
begin
	// Defaults
	ns_i2c_transceiver = I2C_STATE_0_IDLE;

    case (s_i2c_transceiver)
	I2C_STATE_0_IDLE:
		begin
			if ((send_start_bit == 1'b1) && (clk_400KHz == 1'b0))
				ns_i2c_transceiver = I2C_STATE_1_PRE_START;
			else if (send_start_bit == 1'b1)
				ns_i2c_transceiver = I2C_STATE_2_START_BIT;
			else if (send_stop_bit == 1'b1)
				ns_i2c_transceiver = I2C_STATE_5_STOP_BIT;
			else if (transfer_data == 1'b1)
				ns_i2c_transceiver = I2C_STATE_3_TRANSFER_BYTE;
			else
				ns_i2c_transceiver = I2C_STATE_0_IDLE;
		end
	I2C_STATE_1_PRE_START:
		begin
			if (start_and_stop_en == 1'b1)
				ns_i2c_transceiver = I2C_STATE_2_START_BIT;
			else
				ns_i2c_transceiver = I2C_STATE_1_PRE_START;
		end
	I2C_STATE_2_START_BIT:
		begin
			if (change_output_bit_en == 1'b1)
			begin
				if ((transfer_data == 1'b1) && (I2C_BUS_MODE == 1'b0))
					ns_i2c_transceiver = I2C_STATE_3_TRANSFER_BYTE;
				else
					ns_i2c_transceiver = I2C_STATE_6_COMPLETE;
			end
			else
				ns_i2c_transceiver = I2C_STATE_2_START_BIT;
		end
	I2C_STATE_3_TRANSFER_BYTE:
		begin
			if ((current_bit == 3'h0) && (change_output_bit_en == 1'b1))
			begin
				if ((I2C_BUS_MODE == 1'b0) || (num_bits_to_transfer == 3'h6))
					ns_i2c_transceiver = I2C_STATE_4_TRANSFER_ACK;
				else
					ns_i2c_transceiver = I2C_STATE_6_COMPLETE;
			end
			else
				ns_i2c_transceiver = I2C_STATE_3_TRANSFER_BYTE;
		end
	I2C_STATE_4_TRANSFER_ACK:
		begin
			if (change_output_bit_en == 1'b1)
				ns_i2c_transceiver = I2C_STATE_6_COMPLETE;
			else
				ns_i2c_transceiver = I2C_STATE_4_TRANSFER_ACK;
		end
	I2C_STATE_5_STOP_BIT:
		begin
			if (start_and_stop_en == 1'b1)
				ns_i2c_transceiver = I2C_STATE_6_COMPLETE;
			else
				ns_i2c_transceiver = I2C_STATE_5_STOP_BIT;
		end
	I2C_STATE_6_COMPLETE:
		begin
			if (transfer_data == 1'b0)
				ns_i2c_transceiver = I2C_STATE_0_IDLE;
			else
				ns_i2c_transceiver = I2C_STATE_6_COMPLETE;
		end
	default:
		begin
			ns_i2c_transceiver = I2C_STATE_0_IDLE;
		end
	endcase
end

/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/

// Output Registers
always @(posedge clk)
begin
	if (reset == 1'b1)
		i2c_scen <= 1'b1;
	else if (change_output_bit_en & (s_i2c_transceiver == I2C_STATE_2_START_BIT))
		i2c_scen <= 1'b0;
	else if (s_i2c_transceiver == I2C_STATE_5_STOP_BIT)
		i2c_scen <= 1'b1;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		ack <= 1'b0;
	else if (clear_ack == 1'b1)
		ack <= 1'b0;
	else if (start_and_stop_en & (s_i2c_transceiver == I2C_STATE_4_TRANSFER_ACK))
		ack <= i2c_sdata ^ I2C_BUS_MODE;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		data_from_i2c <= 8'h00;
	else if (start_and_stop_en & (s_i2c_transceiver == I2C_STATE_3_TRANSFER_BYTE))
		data_from_i2c <= {data_from_i2c[6:0], i2c_sdata};
end


// Internal Registers
always @(posedge clk)
begin
	if (reset == 1'b1)
		current_bit	<= 3'h0;
	else if ((s_i2c_transceiver == I2C_STATE_3_TRANSFER_BYTE) && 
			(change_output_bit_en == 1'b1))
		current_bit <= current_bit - 3'h1;
	else if (s_i2c_transceiver != I2C_STATE_3_TRANSFER_BYTE)
		current_bit <= num_bits_to_transfer;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		current_byte <= 8'h00;
	else if ((s_i2c_transceiver == I2C_STATE_0_IDLE) || 
			 (s_i2c_transceiver == I2C_STATE_2_START_BIT))
		current_byte <= data_in;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/

assign i2c_sclk		= (I2C_BUS_MODE == 1'b0) ? 
						clk_400KHz :
						((s_i2c_transceiver == I2C_STATE_3_TRANSFER_BYTE) |
						(s_i2c_transceiver == I2C_STATE_4_TRANSFER_ACK)) ?
							clk_400KHz :
							1'b0;

assign i2c_sdata	= 
	(s_i2c_transceiver == I2C_STATE_2_START_BIT) ? 1'b0 :
	(s_i2c_transceiver == I2C_STATE_5_STOP_BIT) ? 1'b0 :
	((s_i2c_transceiver == I2C_STATE_4_TRANSFER_ACK) & read_byte) ? 1'b0 :
	((s_i2c_transceiver == I2C_STATE_3_TRANSFER_BYTE) & ~read_byte) ? 
		current_byte[current_bit]
		: 1'bz;

assign enable_clk	= ~(s_i2c_transceiver == I2C_STATE_0_IDLE) &&
			~(s_i2c_transceiver == I2C_STATE_6_COMPLETE);

assign transfer_complete = 
		(s_i2c_transceiver == I2C_STATE_6_COMPLETE) ? 1'b1 : 1'b0;

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

endmodule

