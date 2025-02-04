// -----------------------------------------------------------------------
// Register file
// 
// Layout:
// ADDR | DATA                                                        | NAME
// -----------------------------------------------------------------------
// 0x00 | 5'b00000 | FX2IFEN | I2SEN | BUFEN                          | ENCTL
// 0x01 | WORDSIZE | MCKDIV[2:0] | CLKSRC | SCKDIV[2:0]               | AUDIFCTL
// 0x02 | BUFCAP[7:0]                                                 | BUFCAP0
// 0x03 | BUFCAP[15:8]                                                | BUFCAP1
// 0x04 | 6'b000000 | BUFCAP[17:16]                                   | BUFCAP2
// 0x05 | 6'b000000 | DOP | DSD                                       | DSDCTL
// 0x06 | RESERVED
// 0x07 | RESERVED
// -----------------------------------------------------------------------

module reg_file #(parameter
    ADDR_WIDTH = 3)(
    input                 rst_n,
    input                 clk,

    input[ADDR_WIDTH-1:0] addr,
    input[7:0]            data,
    input                 wr_en,

    output                audif_rst_n,
    output                audif_word_size,
    output[2:0]           audif_sck_div,
    output[2:0]           audif_mck_div,
    output                audif_clk_src,
	output                audif_dsd_en,
	output                audif_dop_en,

    output                buf_rst_n,
    output[17:0]          buf_cap,
    
    output                fx2if_rst_n);

    localparam STATE_IDLE = 1'b0;
    localparam STATE_WRITE = 1'b1;
    localparam REG_CAPACITY = 'h1 << ADDR_WIDTH;

    reg[7:0]              mem[0:REG_CAPACITY-1];
    reg[7:0]              next_mem[0:REG_CAPACITY-1];

    assign audif_rst_n     = rst_n & mem[0][1];
    assign audif_word_size = mem[1][7];
    assign audif_mck_div   = mem[1][6:4];
	assign audif_clk_src   = mem[1][3];
    assign audif_sck_div   = mem[1][2:0];
    
    assign buf_rst_n       = rst_n & mem[0][0];
    assign buf_cap         = {mem[4][1:0], mem[3], mem[2]};

    assign fx2if_rst_n     = rst_n & mem[0][2];

    assign audif_dsd_en    = mem[5][0];
    assign audif_dop_en    = mem[5][1];

    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < REG_CAPACITY; i = i + 1) 
                mem[i] <= 'h0;
        end else begin
            for (i = 0; i < REG_CAPACITY; i = i + 1) 
                mem[i] <= next_mem[i];
        end
    end

    always @(*) begin
        for (i = 0; i < REG_CAPACITY; i = i + 1) begin
            next_mem[i] = mem[i];
        end
        if (wr_en) begin
            next_mem[addr] = data;
        end
    end

endmodule