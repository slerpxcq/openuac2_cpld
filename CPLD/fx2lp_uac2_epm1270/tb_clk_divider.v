`timescale 1ns/1ps

module tb_clk_divider;
    reg       rst_n;
    reg[3:0]  div; 
    reg       clk_in;
    wire      clk_out;

    clk_divider clk_divider_inst(
        .rst_n(rst_n),
        .div(div),
        .clk_in(clk_in),
        .clk_out(clk_out));

    always #10 clk_in = ~clk_in;
    
    initial begin
        clk_in = 1;
        div <= 4'd3; // div 8
        rst_n = 1;
        #1 rst_n = 0;
        #1 rst_n = 1;
        
        #400 div <= 4'd2;
        #1 rst_n = 0;
        #1 rst_n = 1;

        #400 div <= 4'd4;
        #1 rst_n = 0;
        #1 rst_n = 1;

        #400 $stop;
    end

endmodule