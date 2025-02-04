module dsd_master(
    input        rst_n,
    input        sck_in,

    input        start_n,
    input        stop_n,

    input        dop,

    output       data_req,
    input[15:0]  data_in,

    output       ch1_out,
    output       ch2_out,
    output       sck_out);

    localparam STATE_IDLE = 3'd0;
    localparam STATE_WAIT_DOP = 3'd1;
    localparam STATE_XFER_DOP = 3'd2;
    localparam STATE_WAIT_DSD = 3'd3;
    localparam STATE_XFER_DSD = 3'd4;

    reg[2:0]     state, next_state;
    reg[4:0]     word_bit_count, next_word_bit_count;
    reg[31:0]    ch1_tx_reg, next_ch1_tx_reg;
    reg[31:0]    ch2_tx_reg, next_ch2_tx_reg;
    reg[31:0]    ch1_data_in_reg, next_ch1_data_in_reg;
    reg[31:0]    ch2_data_in_reg, next_ch2_data_in_reg;
	reg[2:0]     req_count, next_req_count;

    wire         sck_out_en;

    assign ch1_out = ch1_tx_reg[0];
    assign ch2_out = ch2_tx_reg[0];
    assign data_req = (dop ? ~word_bit_count[1] : ~word_bit_count[2]);
    assign sck_out_en = (state == STATE_XFER_DOP) | (state == STATE_XFER_DSD);
    assign sck_out = sck_out_en ? sck_in : 1'b1;

    always @(posedge data_req or negedge rst_n) begin
        if (~rst_n) begin
            req_count <= 3'd0;
            ch1_data_in_reg <= 'h0;
            ch2_data_in_reg <= 'h0;
        end else begin
            req_count <= next_req_count;
            ch1_data_in_reg <= next_ch1_data_in_reg;
            ch2_data_in_reg <= next_ch2_data_in_reg;
        end
    end

    always @(*) begin
        next_req_count = req_count + 'h1;
        next_ch1_data_in_reg = ch1_data_in_reg;
        next_ch2_data_in_reg = ch2_data_in_reg;
        case (state) 
        STATE_WAIT_DOP,
        STATE_XFER_DOP: begin
            case (req_count)
            3'd0: next_ch1_data_in_reg[7:0] = data_in[15:8];
            3'd1: next_ch1_data_in_reg[15:8] = data_in[7:0];
            3'd2: next_ch1_data_in_reg[23:16] = data_in[15:8];
            3'd3: next_ch1_data_in_reg[31:24] = data_in[7:0];
            3'd4: next_ch2_data_in_reg[7:0] = data_in[15:8];
            3'd5: next_ch2_data_in_reg[15:8] = data_in[7:0];
            3'd6: next_ch2_data_in_reg[23:16] = data_in[15:8];
            3'd7: next_ch2_data_in_reg[31:24] = data_in[7:0];
            endcase
        end
        STATE_WAIT_DSD,
        STATE_XFER_DSD: begin
            case (req_count[1:0])
            2'd0: next_ch1_data_in_reg[15:0] = data_in;
            2'd1: next_ch1_data_in_reg[31:16] = data_in;
            2'd2: next_ch2_data_in_reg[15:0] = data_in;
            2'd3: next_ch2_data_in_reg[31:16] = data_in;
            endcase
        end
        endcase
    end

    always @(negedge sck_in or negedge rst_n) begin
        if (~rst_n) begin
            state <= STATE_IDLE;
            word_bit_count <= 'h0;
            ch1_tx_reg <= 32'haaaaaaaa;
            ch2_tx_reg <= 32'haaaaaaaa;
        end else begin
            state <= next_state;
            word_bit_count <= next_word_bit_count;
            ch1_tx_reg <= next_ch1_tx_reg;
            ch2_tx_reg <= next_ch2_tx_reg;
        end
    end

    always @(*) begin
        next_state = state;
        next_word_bit_count = word_bit_count;
        next_ch1_tx_reg = ch1_tx_reg;
        next_ch2_tx_reg = ch2_tx_reg;
        case (state)
        STATE_IDLE: begin
            if (~start_n) 
                next_state = dop ? STATE_WAIT_DOP : STATE_WAIT_DSD;
        end
        STATE_WAIT_DOP: begin 
            next_word_bit_count = word_bit_count + 'h1;
            if (next_word_bit_count == 'h0) 
                next_state = STATE_XFER_DOP;
        end
        STATE_WAIT_DSD: begin
            next_word_bit_count = word_bit_count + 'h1;
            if (next_word_bit_count == 'h0) 
                next_state = STATE_XFER_DSD;
        end
        STATE_XFER_DOP,
        STATE_XFER_DSD: begin
            next_word_bit_count = word_bit_count + 'h1;
            next_ch1_tx_reg = ch1_tx_reg >> 'h1;
            next_ch2_tx_reg = ch2_tx_reg >> 'h1;
            if (next_word_bit_count == 'h0) begin
                next_ch1_tx_reg = ch1_data_in_reg;
                next_ch2_tx_reg = ch2_data_in_reg;
                if (~stop_n) 
                    next_state = STATE_IDLE;
            end
        end
        endcase
    end

endmodule