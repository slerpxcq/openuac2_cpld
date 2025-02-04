`timescale 1ns/1ps

`include "spram_async.v"

module tb_circ_buf;
	localparam ADDR_WIDTH = 5;

	reg[ADDR_WIDTH-1:0]  capacity; 
	reg                  rst_n;
	reg                  clk;
	// Write signals
	reg                  wr_en;
	reg[15:0]            wr_data;
	// Read signals	
	reg                  rd_req;
	wire[15:0]           rd_data;
	// SRAM signals
	wire                 sram_oe_n;
	wire                 sram_we_n;
	wire[15:0]           sram_d;
	wire[ADDR_WIDTH-1:0] sram_a;
	// Flags	
	wire                 ff_n, ef_n, half_n;
	wire[ADDR_WIDTH-1:0] size;

	reg[1:0] clk_div_cnt;
	reg      clk_div_out;
	
	circ_buf #(.ADDR_WIDTH(ADDR_WIDTH)) dut(
		.capacity(capacity),
		.rst_n(rst_n),
		.clk(clk),
		.wr_en(wr_en),
		.wr_data(wr_data),
		.rd_req(rd_req),
		.rd_data(rd_data),
		.sram_oe_n(sram_oe_n),
		.sram_we_n(sram_we_n),
		.sram_d(sram_d),
		.sram_a(sram_a),
		.ff_n(ff_n),
		.ef_n(ef_n),
		.half_n(half_n),
		.size(size));

	spram_async #(
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(16)) ram0(
		.a(sram_a),
		.dq(sram_d),
		.ce_n(1'b0),
		.we_n(sram_we_n),
		.oe_n(sram_oe_n));

	always #10 clk = ~clk;
	
	always @(posedge clk) begin
		clk_div_cnt = clk_div_cnt + 1;
		if (clk_div_cnt == 2)
			clk_div_cnt = 0;
		if (clk_div_cnt == 0)
			clk_div_out = ~clk_div_out;
	end
	
	initial begin
		clk = 1;
		clk_div_out = 1;
		clk_div_cnt = 0;
		capacity = 5'd24;
		rst_n = 1;
		wr_en = 0;
		wr_data = 'h0;
		rd_req = 0;
		#1 rst_n = 0;
		#1 rst_n = 1;
		
		// test write 
		#40 @(posedge clk) wr_en = 1;
		repeat (27) begin
			@(posedge clk) begin
				wr_data = wr_data + 'h1;
			end
		end
		wr_en = 0;
		
		// test read
		repeat (60) begin
			@(posedge clk_div_out) begin
				rd_req = ~rd_req;
			end
		end
		#1000 $stop;
	end
	
endmodule