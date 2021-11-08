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
 * This module loads data into the TRDB DC2 camera's control registers        *
 *  after system reset.                                                       *
 *                                                                            *
 ******************************************************************************/

module Altera_UP_I2C_DC_Auto_Initialize (
	// Inputs
	clk,
	reset,

	clear_error,

	ack,
	transfer_complete,

	// Bidirectionals

	// Outputs
	data_out,
	transfer_data,
	send_start_bit,
	send_stop_bit,
	
	auto_init_complete,
	auto_init_error
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter DC_ROW_START			= 16'h000C;
parameter DC_COLUMN_START		= 16'h001E;
parameter DC_ROW_WIDTH			= 16'h0400;
parameter DC_COLUMN_WIDTH		= 16'h0500;
parameter DC_H_BLANK_B			= 16'h018C;
parameter DC_V_BLANK_B			= 16'h0032;
parameter DC_H_BLANK_A			= 16'h00C6;
parameter DC_V_BLANK_A			= 16'h0019;
parameter DC_SHUTTER_WIDTH		= 16'h0432;
parameter DC_ROW_SPEED			= 16'h0011;
parameter DC_EXTRA_DELAY		= 16'h0000;
parameter DC_SHUTTER_DELAY		= 16'h0000;
parameter DC_RESET				= 16'h0008;
parameter DC_FRAME_VALID		= 16'h0000;
parameter DC_READ_MODE_B		= 16'h0200;
parameter DC_READ_MODE_A		= 16'h040C;
parameter DC_DARK_COL_ROW		= 16'h0129;
parameter DC_FLASH				= 16'h0608;
parameter DC_GREEN_GAIN_1		= 16'h0020;
parameter DC_BLUE_GAIN			= 16'h0020;
parameter DC_RED_GAIN			= 16'h0020;
parameter DC_GREEN_GAIN_2		= 16'h0020;
parameter DC_GLOBAL_GAIN		= 16'h0020;
parameter DC_CONTEXT_CTRL		= 16'h000B;

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input				clk;
input				reset;

input				clear_error;

input				ack;
input				transfer_complete;

// Bidirectionals

// Outputs
output	reg	[7:0]	data_out;
output	reg			transfer_data;
output	reg			send_start_bit;
output	reg			send_stop_bit;


output				auto_init_complete;
output	reg			auto_init_error;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// States
localparam	AUTO_STATE_0_CHECK_STATUS		= 4'h0,
			AUTO_STATE_1_SEND_START_BIT		= 4'h1,
			AUTO_STATE_2_TRANSFER_BYTE_0	= 4'h2,
			AUTO_STATE_3_TRANSFER_BYTE_1	= 4'h3,
			AUTO_STATE_4_TRANSFER_BYTE_2	= 4'h4,
			AUTO_STATE_5_WAIT				= 4'h5,
			AUTO_STATE_6_SEND_STOP_BIT		= 4'h6,
			AUTO_STATE_7_INCREASE_COUNTER	= 4'h7,
			AUTO_STATE_8_DONE				= 4'h8;

localparam	MIN_ROM_ADDRESS	= 5'h00;
localparam	MAX_ROM_ADDRESS	= 5'h18;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				change_state;

wire				finished_auto_init;

// Internal Registers
reg			[4:0]	rom_address_counter;
reg			[25:0]	rom_data;

// State Machine Registers
reg			[3:0]	ns_i2c_auto_init;
reg			[3:0]	s_i2c_auto_init;

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/

always @(posedge clk)
begin
	if (reset == 1'b1)
		s_i2c_auto_init <= AUTO_STATE_0_CHECK_STATUS;
	else
		s_i2c_auto_init <= ns_i2c_auto_init;
end

always @(*)
begin
	// Defaults
	ns_i2c_auto_init = AUTO_STATE_0_CHECK_STATUS;

    case (s_i2c_auto_init)
	AUTO_STATE_0_CHECK_STATUS:
		begin
			if (finished_auto_init == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_8_DONE;
			else if (rom_data[25] == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_1_SEND_START_BIT;
			else
				ns_i2c_auto_init = AUTO_STATE_3_TRANSFER_BYTE_1;
		end
	AUTO_STATE_1_SEND_START_BIT:
		begin
			if (change_state == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_2_TRANSFER_BYTE_0;
			else
				ns_i2c_auto_init = AUTO_STATE_1_SEND_START_BIT;
		end
	AUTO_STATE_2_TRANSFER_BYTE_0:
		begin
			if (change_state == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_3_TRANSFER_BYTE_1;
			else
				ns_i2c_auto_init = AUTO_STATE_2_TRANSFER_BYTE_0;
		end
	AUTO_STATE_3_TRANSFER_BYTE_1:
		begin
			if (change_state == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_4_TRANSFER_BYTE_2;
			else
				ns_i2c_auto_init = AUTO_STATE_3_TRANSFER_BYTE_1;
		end
	AUTO_STATE_4_TRANSFER_BYTE_2:
		begin
			if ((change_state == 1'b1) && (rom_data[24] == 1'b1))
				ns_i2c_auto_init = AUTO_STATE_5_WAIT;
			else if (change_state == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_7_INCREASE_COUNTER;
			else
				ns_i2c_auto_init = AUTO_STATE_4_TRANSFER_BYTE_2;
		end
	AUTO_STATE_5_WAIT:
		begin
			if (transfer_complete == 1'b0)
				ns_i2c_auto_init = AUTO_STATE_6_SEND_STOP_BIT;
			else
				ns_i2c_auto_init = AUTO_STATE_5_WAIT;
		end
	AUTO_STATE_6_SEND_STOP_BIT:
		begin
			if (transfer_complete == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_7_INCREASE_COUNTER;
			else
				ns_i2c_auto_init = AUTO_STATE_6_SEND_STOP_BIT;
		end
	AUTO_STATE_7_INCREASE_COUNTER:
		begin
			ns_i2c_auto_init = AUTO_STATE_0_CHECK_STATUS;
		end
	AUTO_STATE_8_DONE:
		begin
			ns_i2c_auto_init = AUTO_STATE_8_DONE;
		end
	default:
		begin
			ns_i2c_auto_init = AUTO_STATE_0_CHECK_STATUS;
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
		data_out <= 8'h00;
	else if (s_i2c_auto_init == AUTO_STATE_1_SEND_START_BIT)
		data_out <= 8'hBA;
	else if (s_i2c_auto_init == AUTO_STATE_2_TRANSFER_BYTE_0)
		data_out <= rom_data[23:16];
	else if (s_i2c_auto_init == AUTO_STATE_0_CHECK_STATUS)
		data_out <= rom_data[15: 8];
	else if (s_i2c_auto_init == AUTO_STATE_3_TRANSFER_BYTE_1)
		data_out <= rom_data[15: 8];
	else if (s_i2c_auto_init == AUTO_STATE_4_TRANSFER_BYTE_2)
		data_out <= rom_data[ 7: 0];
end

always @(posedge clk)
begin
	if (reset == 1'b1) 
		transfer_data <= 1'b0;
	else if (transfer_complete == 1'b1)
		transfer_data <= 1'b0;
	else if (s_i2c_auto_init == AUTO_STATE_1_SEND_START_BIT)
		transfer_data <= 1'b1;
	else if (s_i2c_auto_init == AUTO_STATE_2_TRANSFER_BYTE_0)
		transfer_data <= 1'b1;
	else if (s_i2c_auto_init == AUTO_STATE_3_TRANSFER_BYTE_1)
		transfer_data <= 1'b1;
	else if (s_i2c_auto_init == AUTO_STATE_4_TRANSFER_BYTE_2)
		transfer_data <= 1'b1;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		send_start_bit <= 1'b0;
	else if (transfer_complete == 1'b1)
		send_start_bit <= 1'b0;
	else if (s_i2c_auto_init == AUTO_STATE_1_SEND_START_BIT)
		send_start_bit <= 1'b1;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		send_stop_bit <= 1'b0;
	else if (transfer_complete == 1'b1)
		send_stop_bit <= 1'b0;
	else if (s_i2c_auto_init == AUTO_STATE_6_SEND_STOP_BIT)
		send_stop_bit <= 1'b1;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		auto_init_error <= 1'b0;
	else if (clear_error == 1'b1)
		auto_init_error <= 1'b0;
	else if ((s_i2c_auto_init == AUTO_STATE_7_INCREASE_COUNTER) & ack)
		auto_init_error <= 1'b1;
end

// Internal Registers
always @(posedge clk)
begin
	if (reset == 1'b1)
		rom_address_counter <= MIN_ROM_ADDRESS;
	else if (s_i2c_auto_init == AUTO_STATE_7_INCREASE_COUNTER)
		rom_address_counter <= rom_address_counter + 5'h01;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/
// Output Assignments
assign auto_init_complete = (s_i2c_auto_init == AUTO_STATE_8_DONE);


// Internals Assignments
assign change_state	= transfer_complete & transfer_data;

assign finished_auto_init = (rom_address_counter == MAX_ROM_ADDRESS);

always @(*)
begin
	case (rom_address_counter)
	0		:	rom_data	<=	{10'h201, DC_ROW_START};
	1		:	rom_data	<=	{10'h002, DC_COLUMN_START};
	2		:	rom_data	<=	{10'h003, DC_ROW_WIDTH};
	3		:	rom_data	<=	{10'h004, DC_COLUMN_WIDTH};
	4		:	rom_data	<=	{10'h005, DC_H_BLANK_B};
	5		:	rom_data	<=	{10'h006, DC_V_BLANK_B};
	6		:	rom_data	<=	{10'h007, DC_H_BLANK_A};
	7		:	rom_data	<=	{10'h008, DC_V_BLANK_A};
	8		:	rom_data	<=	{10'h009, DC_SHUTTER_WIDTH};
	9		:	rom_data	<=	{10'h00A, DC_ROW_SPEED};
	10		:	rom_data	<=	{10'h00B, DC_EXTRA_DELAY};
	11		:	rom_data	<=	{10'h00C, DC_SHUTTER_DELAY};
	12		:	rom_data	<=	{10'h10D, DC_RESET};
	13		:	rom_data	<=	{10'h21F, DC_FRAME_VALID};
	14		:	rom_data	<=	{10'h020, DC_READ_MODE_B};
	15		:	rom_data	<=	{10'h021, DC_READ_MODE_A};
	16		:	rom_data	<=	{10'h022, DC_DARK_COL_ROW};
	17		:	rom_data	<=	{10'h123, DC_FLASH};
	18		:	rom_data	<=	{10'h22B, DC_GREEN_GAIN_1};
	19		:	rom_data	<=	{10'h02C, DC_BLUE_GAIN};
	20		:	rom_data	<=	{10'h02D, DC_RED_GAIN};
	21		:	rom_data	<=	{10'h02E, DC_GREEN_GAIN_2};
	22		:	rom_data	<=	{10'h12F, DC_GLOBAL_GAIN};
	23		:	rom_data	<=	{10'h3C8, DC_CONTEXT_CTRL};
	default	:	rom_data	<=	26'h1000000;
	endcase
end

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

