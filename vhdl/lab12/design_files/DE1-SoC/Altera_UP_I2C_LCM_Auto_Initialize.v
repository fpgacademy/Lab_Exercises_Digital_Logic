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
 * This module loads data into the TRDB LCM screen's control registers        *
 *  after system reset.                                                       *
 *                                                                            *
 ******************************************************************************/

module Altera_UP_I2C_LCM_Auto_Initialize (
	// Inputs
	clk,
	reset,

	clear_error,

	ack,
	transfer_complete,

	// Bidirectionals

	// Outputs
	data_out,
	data_size,
	transfer_data,
	send_start_bit,
	send_stop_bit,
	
	auto_init_complete,
	auto_init_error
);

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter LCM_INPUT_FORMAT_UB			= 8'h00;
parameter LCM_INPUT_FORMAT_LB			= 8'h01;
parameter LCM_POWER						= 8'h3F;
parameter LCM_DIRECTION_AND_PHASE		= 8'h17;
parameter LCM_HORIZONTAL_START_POSITION	= 8'h18;
parameter LCM_VERTICAL_START_POSITION	= 8'h08;
parameter LCM_ENB_NEGATIVE_POSITION		= 8'h00;
parameter LCM_GAIN_OF_CONTRAST			= 8'h20;
parameter LCM_R_GAIN_OF_SUB_CONTRAST	= 8'h20;
parameter LCM_B_GAIN_OF_SUB_CONTRAST	= 8'h20;
parameter LCM_OFFSET_OF_BRIGHTNESS		= 8'h10;
parameter LCM_VCOM_HIGH_LEVEL			= 8'h3F;
parameter LCM_VCOM_LOW_LEVEL			= 8'h3F;
parameter LCM_PCD_HIGH_LEVEL			= 8'h2F;
parameter LCM_PCD_LOW_LEVEL				= 8'h2F;
parameter LCM_GAMMA_CORRECTION_0		= 8'h98;
parameter LCM_GAMMA_CORRECTION_1		= 8'h9A;
parameter LCM_GAMMA_CORRECTION_2		= 8'hA9;
parameter LCM_GAMMA_CORRECTION_3		= 8'h99;
parameter LCM_GAMMA_CORRECTION_4		= 8'h08;

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
output	reg	[2:0]	data_size;
output	reg			transfer_data;
output	reg			send_start_bit;
output	reg			send_stop_bit;


output				auto_init_complete;
output	reg			auto_init_error;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/
// States
localparam	AUTO_STATE_0_CHECK_STATUS		= 3'h0,
			AUTO_STATE_1_SEND_START_BIT		= 3'h1,
			AUTO_STATE_2_TRANSFER_BYTE_0	= 3'h2,
			AUTO_STATE_3_TRANSFER_BYTE_1	= 3'h3,
			AUTO_STATE_4_WAIT				= 3'h4,
			AUTO_STATE_5_SEND_STOP_BIT		= 3'h5,
			AUTO_STATE_6_INCREASE_COUNTER	= 3'h6,
			AUTO_STATE_7_DONE				= 3'h7;

localparam	MIN_ROM_ADDRESS	= 5'h00;
localparam	MAX_ROM_ADDRESS	= 5'h14;

/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/
// Internal Wires
wire				change_state;

wire				finished_auto_init;

// Internal Registers
reg			[4:0]	rom_address_counter;
reg			[13:0]	rom_data;

// State Machine Registers
reg			[2:0]	ns_i2c_auto_init;
reg			[2:0]	s_i2c_auto_init;

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
				ns_i2c_auto_init = AUTO_STATE_7_DONE;
			else
				ns_i2c_auto_init = AUTO_STATE_1_SEND_START_BIT;
		end
	AUTO_STATE_1_SEND_START_BIT:
		begin
			if (transfer_complete == 1'b1)
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
				ns_i2c_auto_init = AUTO_STATE_4_WAIT;
			else
				ns_i2c_auto_init = AUTO_STATE_3_TRANSFER_BYTE_1;
		end
	AUTO_STATE_4_WAIT:
		begin
			if (transfer_complete == 1'b0)
				ns_i2c_auto_init = AUTO_STATE_5_SEND_STOP_BIT;
			else
				ns_i2c_auto_init = AUTO_STATE_4_WAIT;
		end
	AUTO_STATE_5_SEND_STOP_BIT:
		begin
			if (transfer_complete == 1'b1)
				ns_i2c_auto_init = AUTO_STATE_6_INCREASE_COUNTER;
			else
				ns_i2c_auto_init = AUTO_STATE_5_SEND_STOP_BIT;
		end
	AUTO_STATE_6_INCREASE_COUNTER:
		begin
			ns_i2c_auto_init = AUTO_STATE_0_CHECK_STATUS;
		end
	AUTO_STATE_7_DONE:
		begin
			ns_i2c_auto_init = AUTO_STATE_7_DONE;
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
		data_out <= {1'b0, rom_data[13: 8], 1'b0};
	else if (s_i2c_auto_init == AUTO_STATE_3_TRANSFER_BYTE_1)
		data_out <= rom_data[ 7: 0];
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		data_size <= 3'h0;
	else if (s_i2c_auto_init == AUTO_STATE_1_SEND_START_BIT)
		data_size <= 3'h6;
	else if (s_i2c_auto_init == AUTO_STATE_3_TRANSFER_BYTE_1)
		data_size <= 3'h7;
end

always @(posedge clk)
begin
	if (reset == 1'b1) 
		transfer_data <= 1'b0;
	else if (transfer_complete == 1'b1)
		transfer_data <= 1'b0;
	else if (s_i2c_auto_init == AUTO_STATE_2_TRANSFER_BYTE_0)
		transfer_data <= 1'b1;
	else if (s_i2c_auto_init == AUTO_STATE_3_TRANSFER_BYTE_1)
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
	else if (s_i2c_auto_init == AUTO_STATE_5_SEND_STOP_BIT)
		send_stop_bit <= 1'b1;
end

always @(posedge clk)
begin
	if (reset == 1'b1)
		auto_init_error <= 1'b0;
	else if (clear_error == 1'b1)
		auto_init_error <= 1'b0;
	else if ((s_i2c_auto_init == AUTO_STATE_6_INCREASE_COUNTER) & ack)
		auto_init_error <= 1'b1;
end

// Internal Registers
always @(posedge clk)
begin
	if (reset == 1'b1)
		rom_address_counter <= MIN_ROM_ADDRESS;
	else if (s_i2c_auto_init == AUTO_STATE_6_INCREASE_COUNTER)
		rom_address_counter <= rom_address_counter + 5'h01;
end

/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/
// Output Assignments
assign auto_init_complete = (s_i2c_auto_init == AUTO_STATE_7_DONE);


// Internals Assignments
assign change_state	= transfer_complete & transfer_data;

assign finished_auto_init = (rom_address_counter == MAX_ROM_ADDRESS);

always @(*)
begin
	case (rom_address_counter)
	0		:	rom_data	<=	{6'h02, LCM_INPUT_FORMAT_UB};
	1		:	rom_data	<=	{6'h03, LCM_INPUT_FORMAT_LB};
	2		:	rom_data	<=	{6'h04, LCM_POWER};
	3		:	rom_data	<=	{6'h05, LCM_DIRECTION_AND_PHASE};
	4		:	rom_data	<=	{6'h06, LCM_HORIZONTAL_START_POSITION};
	5		:	rom_data	<=	{6'h07, LCM_VERTICAL_START_POSITION};
	6		:	rom_data	<=	{6'h08, LCM_ENB_NEGATIVE_POSITION};
	7		:	rom_data	<=	{6'h09, LCM_GAIN_OF_CONTRAST};
	8		:	rom_data	<=	{6'h0A, LCM_R_GAIN_OF_SUB_CONTRAST};
	9		:	rom_data	<=	{6'h0B, LCM_B_GAIN_OF_SUB_CONTRAST};
	10		:	rom_data	<=	{6'h0C, LCM_OFFSET_OF_BRIGHTNESS};
	11		:	rom_data	<=	{6'h10, LCM_VCOM_HIGH_LEVEL};
	12		:	rom_data	<=	{6'h11, LCM_VCOM_LOW_LEVEL};
	13		:	rom_data	<=	{6'h12, LCM_PCD_HIGH_LEVEL};
	14		:	rom_data	<=	{6'h13, LCM_PCD_LOW_LEVEL};
	15		:	rom_data	<=	{6'h14, LCM_GAMMA_CORRECTION_0};
	16		:	rom_data	<=	{6'h15, LCM_GAMMA_CORRECTION_1};
	17		:	rom_data	<=	{6'h16, LCM_GAMMA_CORRECTION_2};
	18		:	rom_data	<=	{6'h17, LCM_GAMMA_CORRECTION_3};
	19		:	rom_data	<=	{6'h18, LCM_GAMMA_CORRECTION_4};
	default	:	rom_data	<=	14'h0000;
	endcase
end

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

