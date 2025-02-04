module audio_if(    
    input                   rst_n,
    input                   clk, 
    input                   word_size, // 0 -> 16bit, 1 -> 32bit
    input[2:0]              sck_div_in, 
    input[2:0]              mck_div_in,

    output                  data_req,
    input                   data_ok,
    input[15:0]             data_in,

    input                   start_n,
    input                   stop_n,

    input                   dop,
    input                   dsd,

    output                  aud_mck, 
    output                  aud_sck,
    output                  aud_ws_dsd1,
    output                  aud_sd_dsd2);

    reg[15:0]               data_in_reg;

    wire                    ws, sd, sck;
    wire                    dsd1, dsd2;
    wire                    sck_out_i2s, sck_out_dsd;
    wire                    data_req_i2s, data_req_dsd;
    wire                    i2s_rst_n, dsd_rst_n;
    wire                    dsd_en;
    wire[2:0]               sck_div; 

	assign dsd_en = dop | dsd;
    assign sck_div = dop ? (sck_div_in + 'h2) : 
                     dsd ? (sck_div_in + 'h1) : sck_div_in; 
    assign dsd_rst_n = dsd_en & rst_n;
    assign i2s_rst_n = ~dsd_en & rst_n;

    assign aud_ws_dsd1 = dsd_en ? dsd1 : ws;
    assign aud_sd_dsd2 = dsd_en ? dsd2 : sd;
    assign aud_sck = dsd_en ? sck_out_dsd : sck_out_i2s;
	assign data_req = dsd_en ? data_req_dsd : data_req_i2s;

    always @(posedge data_ok) begin
        data_in_reg <= data_in;
    end

    clk_divider clk_div_inst(
        .rst_n(rst_n),
        .div1(sck_div),
        .div2(mck_div_in),
        .clk_in(clk),
        .clk1_out(sck),
        .clk2_out(aud_mck));

    i2s_master i2s_master_inst(
        .rst_n(i2s_rst_n),
        .word_size(word_size), 
        .data_req(data_req_i2s),
        .data_in(data_in_reg),
        .start_n(start_n),
        .stop_n(stop_n),
        .sck_in(sck),
        .sck_out(sck_out_i2s),
        .ws(ws),
        .sd(sd));
    
    dsd_master dsd_master_inst(
        .rst_n(dsd_rst_n),
        .sck_in(sck), 
        .start_n(start_n),
        .stop_n(stop_n),
        .dop(dop),
        .data_req(data_req_dsd),
        .data_in(data_in_reg),
        .ch1_out(dsd1),
        .ch2_out(dsd2),
        .sck_out(sck_out_dsd));

endmodule