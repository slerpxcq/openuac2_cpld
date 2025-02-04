`timescale 1ns/1ps

`include "dop_if.v"

module tb_dop_if;
    reg        rst_n;
    reg        clk; // sck, not mck

    wire       data_req_out;
    reg[15:0]  data_in;
    wire[1:0]  sd_out;
    wire       sck_out;
    reg[7:0]   rand;

    reg        start_n;
    reg        stop_n;

    dsd_master dut(
        .rst_n(rst_n),
        .clk(clk),
        .data_req_out(data_req_out),
        .data_in(data_in),
        .sd_out(sd_out),
        .sck_out(sck_out),
        .start_n(start_n),
        .stop_n(stop_n));

    always #10 clk = ~clk;

    initial begin
        rst_n = 0;
        clk = 1;
        start_n = 1;
        stop_n = 1;
        #5 rst_n = 1;
        data_in = 16'h0;
        #100 start_n = 0;
        repeat (10) begin
            repeat (2) begin
                @(posedge data_req_out) begin
                    rand = $urandom;
                    data_in = {rand, 8'h00};
                end
                @(posedge data_req_out) begin
                    rand = $urandom;
                    data_in = {8'h05, rand};
                end
            end
            repeat (2) begin
                @(posedge data_req_out) begin
                    rand = $urandom;
                    data_in = {rand, 8'h00};
                end
                @(posedge data_req_out) begin
                    rand = $urandom;
                    data_in = {8'hfa, rand};
                end
            end
        end
        start_n = 1;
        stop_n = 0;
        #1000 $stop;
    end

endmodule