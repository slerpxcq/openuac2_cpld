`timescale 1ns/1ps

module spram_async #(parameter
    DATA_WIDTH = 16,
    ADDR_WIDTH = 6)(
    input[ADDR_WIDTH-1:0] a, 
    inout[DATA_WIDTH-1:0] dq, 
    input                 ce_n, 
    input                 we_n, 
    input                 oe_n);          

    localparam CAPACITY = 1 << ADDR_WIDTH;
	 
    reg [DATA_WIDTH-1:0] data_reg;
    reg [DATA_WIDTH-1:0] mem [0:CAPACITY-1];
	 
	assign #1 dq = (~ce_n & ~oe_n & we_n) ? data_reg : 'hz;

	initial begin
		data_reg = 'hffff;
	end

	always @(*) begin
        if (~ce_n) begin
            if (~we_n) 
                mem[a] = dq;
            if (~oe_n)
                data_reg = mem[a];
        end
	end

endmodule 