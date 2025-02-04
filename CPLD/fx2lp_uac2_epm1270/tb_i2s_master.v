`timescale 1ns/1ps

module tb_i2s_master;
    reg[1:0]              word_size;
    reg[3:0]              sck_div; 
    reg                   rst_n;
    reg                   clk;

    wire                  data_req;
    reg[15:0]             data_in;

    reg                   half_n;
    reg                   ef_n;
    
    wire                  sck;
    wire                  ws;
    wire                  sd;

    i2s_master i2s_master_inst(
        .word_size(word_size),
        .sck_div(sck_div),
        .rst_n(rst_n),
        .clk(clk),
        .data_req(data_req),
        .data_in(data_in),
        .half_n(half_n),
        .ef_n(ef_n),
        .sck(sck),
        .ws(ws),
        .sd(sd));

    always #10 clk = ~clk;

    initial begin
        word_size = 2'd0;
        sck_div = 4'd0;
        rst_n = 1'b1;
        clk = 1;
        data_in = 'd0;
        half_n = 1'b1;
        ef_n = 1'b1;
        #1 rst_n = 0;
        #1 rst_n = 1;

        #100 half_n = 0;
        repeat (20) begin
            @(posedge data_req) begin
                data_in = data_in + 1;
            end
        end
        #50 ef_n = 0;
        #1000 $stop;
    end

endmodule