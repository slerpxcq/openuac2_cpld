module clk_divider(
    input       rst_n,
    input[2:0]  div1, // divide by 2^(div), up to 7
    input[2:0]  div2,
    input       clk_in,
    output      clk1_out,
    output      clk2_out);

    // reg[2:0]     div1_reg;
    // reg[2:0]     div2_reg;
    wire[7:0]    clk_div;

    assign clk_div[0] = clk_in;

    dff dff_inst0(
        .clk(clk_div[0]),
        .clrn(rst_n),
        .d(~clk_div[1]),
        .q(clk_div[1]),
        .prn(1'b1));

    genvar i;
    generate 
        for (i = 2; i < 8; i = i + 1) begin: _
            dff dff_inst(
                .clk(clk_div[i-1]),
                .clrn(rst_n),
                .d(~clk_div[i]),
                .q(clk_div[i]),
                .prn(1'b1));
        end
    endgenerate

    assign clk1_out = 
        div1 == 3'd0 ? clk_div[0] :
        div1 == 3'd1 ? clk_div[1] :
        div1 == 3'd2 ? clk_div[2] :
        div1 == 3'd3 ? clk_div[3] :
        div1 == 3'd4 ? clk_div[4] :
        div1 == 3'd5 ? clk_div[5] :
        div1 == 3'd6 ? clk_div[6] :
        div1 == 3'd7 ? clk_div[7] : clk_div[0];

    assign clk2_out = 
        div2 == 3'd0 ? clk_div[0] :
        div2 == 3'd1 ? clk_div[1] :
        div2 == 3'd2 ? clk_div[2] :
        div2 == 3'd3 ? clk_div[3] :
        div2 == 3'd4 ? clk_div[4] :
        div2 == 3'd5 ? clk_div[5] :
        div2 == 3'd6 ? clk_div[6] :
        div2 == 3'd7 ? clk_div[7] : clk_div[0];

    // always @(posedge rst_n) begin
    //     div1_reg <= div1;
    //     div2_reg <= div2;
    // end

endmodule