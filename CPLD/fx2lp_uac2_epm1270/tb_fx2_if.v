`timescale 1ns/1ps

module tb_fx2_if;
	// inputs
	reg        rst_n;
	reg        ifclk;
	wire[15:0] fd;
	reg        ef_n, ff_n;
	wire       slrd_n, slwr_n, sloe_n; 

	// outputs
	wire[15:0] data_out;
	wire       data_valid_n;
	
	fx2_if dut(
		.rst_n(rst_n),
		.ifclk(ifclk),
		.fd(fd),
		.ff_n(ff_n), .ef_n(ef_n),
		.slrd_n(slrd_n), 
		.slwr_n(slwr_n),
		.sloe_n(sloe_n),
		.pktend_n(),
		.data_valid_n(data_valid_n));

	reg[3:0] pulse_count;
	reg[15:0] fd_reg;

	assign fd = sloe_n ? 'hz : fd_reg;

	// 33MHz ifclk	
	always #30 ifclk = ~ifclk;
	
	initial begin
		rst_n = 1;
		#5 rst_n = 0;
		#5 rst_n = 1;
		pulse_count = 'd0;
		fd_reg = 'd0;
		ifclk = 0;
		ef_n = 0;
		ff_n = 1;
		#3000 $stop;
	end


	// read behaviour: 
	// 12 datas is avaliable per 16 cycles
	always @(posedge ifclk) begin
		pulse_count = pulse_count + 1;
		ef_n = (pulse_count > 4);
		if (!slrd_n) begin
			fd_reg = fd_reg + 1;
		end
	end

endmodule