module circ_buf #(parameter 
	ADDR_WIDTH = 18)(
	input[ADDR_WIDTH-1:0]      capacity, // in 16-bit words, should not change during operation
	input                      rst_n,
	input                      clk,

	// Write signals
	input                      wr_en,
	input[15:0]                wr_data,

	// Read signals	
	input                      rd_req,
	output                     rd_ok,
	output[15:0]               rd_data,

	// SRAM signals
	output                     sram_oe_n,
	output                     sram_we_n,
	inout[15:0]                sram_d,
	output[ADDR_WIDTH-1:0]     sram_a,

	// Flags	
	output reg                 ff_n, ef_n,
	output reg                 half_n);

	reg[ADDR_WIDTH-1:0]        wr_addr, rd_addr;
	wire[ADDR_WIDTH-1:0]       wr_addr_plus_one, rd_addr_plus_one;
	wire[ADDR_WIDTH-1:0]       wr_addr_plus_one_wrap, rd_addr_plus_one_wrap;
	reg[ADDR_WIDTH-1:0]        next_wr_addr, next_rd_addr;
	reg[ADDR_WIDTH-1:0]        size, next_size;
	reg                        next_ff_n, next_ef_n;
	reg                        next_half_n;

	wire[ADDR_WIDTH-1:0]       half_capacity;
	wire                       rd_en;  
	wire                       do_write, do_read;

	pos_edge_det rd_req_det(
		.rst_n(rst_n),
		.clk(clk),
		.in(rd_req),
		.out(rd_en));

	assign rd_data = ef_n ? sram_d : 'h0;
	assign rd_ok = ~rd_en;
	assign half_capacity = capacity >> 'h1;
	assign do_write = wr_en & ff_n;
	assign do_read = rd_en & ef_n;
	assign sram_we_n = ~(do_write & clk);
	assign sram_oe_n = ~(do_read & ~clk);
	assign sram_d = ~sram_we_n ? wr_data : 'hz;
	assign sram_a = ~sram_we_n ? wr_addr :
	                ~sram_oe_n ? rd_addr : 'hz;
	assign wr_addr_plus_one = wr_addr + 'h1;
	assign rd_addr_plus_one = rd_addr + 'h1;
	assign wr_addr_plus_one_wrap = (wr_addr_plus_one == capacity) ? 'h0 : wr_addr_plus_one;
	assign rd_addr_plus_one_wrap = (rd_addr_plus_one == capacity) ? 'h0 : rd_addr_plus_one;

	always @(posedge clk or negedge rst_n) begin
		if (~rst_n) begin
			wr_addr <= 'h0;
			rd_addr <= 'h0;
			size <= 'h0;
			ef_n <= 1'b0;
			ff_n <= 1'b1;
			half_n <= 1'b1;
		end else begin
			wr_addr <= next_wr_addr;
			rd_addr <= next_rd_addr;
			size <= next_size;
			ef_n <= next_ef_n;
			ff_n <= next_ff_n;
			half_n <= next_half_n;
		end
	end

	always @(*) begin
		next_wr_addr = wr_addr;
		next_rd_addr = rd_addr;
		next_size = size;
		next_ef_n = ef_n;
		next_ff_n = ff_n;
		if (do_write & do_read) begin
			next_wr_addr = wr_addr_plus_one_wrap;
			next_rd_addr = rd_addr_plus_one_wrap;
		end else if (do_write) begin
			next_size = size + 'h1;
			next_ef_n = 1'b1;
			next_wr_addr = wr_addr_plus_one_wrap;
			if (next_wr_addr == rd_addr) 
				next_ff_n = 1'b0;
		end else if (do_read) begin
			next_size = size - 'h1;
			next_ff_n = 1'b1;
			next_rd_addr = rd_addr_plus_one_wrap;
			if (next_rd_addr == wr_addr)
				next_ef_n = 1'b0;
		end
		next_half_n = (next_size < half_capacity);
	end
	
endmodule