//lpm_ram_dq CBX_SINGLE_OUTPUT_FILE="ON" INTENDED_DEVICE_FAMILY=""MAX II"" LPM_ADDRESS_CONTROL="REGISTERED" LPM_INDATA="REGISTERED" LPM_OUTDATA="REGISTERED" LPM_WIDTH=8 LPM_WIDTHAD=8 address data inclock outclock q we
//VERSION_BEGIN 21.1 cbx_mgl 2021:10:21:11:03:46:SJ cbx_stratixii 2021:10:21:11:03:22:SJ cbx_util_mgl 2021:10:21:11:03:22:SJ  VERSION_END
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2021  Intel Corporation. All rights reserved.
//  Your use of Intel Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Intel Program License 
//  Subscription Agreement, the Intel Quartus Prime License Agreement,
//  the Intel FPGA IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Intel and sold by Intel or its authorized distributors.  Please
//  refer to the applicable agreement for further details, at
//  https://fpgasoftware.intel.com/eula.



//synthesis_resources = lpm_ram_dq 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  mg02k
	( 
	address,
	data,
	inclock,
	outclock,
	q,
	we) /* synthesis synthesis_clearbox=1 */;
	input   [7:0]  address;
	input   [7:0]  data;
	input   inclock;
	input   outclock;
	output   [7:0]  q;
	input   we;

	wire  [7:0]   wire_mgl_prim1_q;

	lpm_ram_dq   mgl_prim1
	( 
	.address(address),
	.data(data),
	.inclock(inclock),
	.outclock(outclock),
	.q(wire_mgl_prim1_q),
	.we(we));
	defparam
		mgl_prim1.intended_device_family = ""MAX II"",
		mgl_prim1.lpm_address_control = "REGISTERED",
		mgl_prim1.lpm_indata = "REGISTERED",
		mgl_prim1.lpm_outdata = "REGISTERED",
		mgl_prim1.lpm_width = 8,
		mgl_prim1.lpm_widthad = 8;
	assign
		q = wire_mgl_prim1_q;
endmodule //mg02k
//VALID FILE
