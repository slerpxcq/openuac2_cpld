module i2s_master(
    input                   rst_n,
    input                   word_size, // 0 -> 16bit, 1 -> 32bit

    output                  data_req,
    input[15:0]             data_in,

    input                   start_n,
    input                   stop_n,

    input                   sck_in,
    output                  sck_out,
    output reg              ws,
    output                  sd);

    localparam STATE_IDLE       = 2'd0;
    localparam STATE_WAIT       = 2'd1;
    localparam STATE_XFER       = 2'd2;

    reg[1:0]                state, next_state;
    reg[15:0]               tx_reg, next_tx_reg;
    reg                     next_ws;

    reg[4:0]                word_bit_count, next_word_bit_count;
    wire[4:0]               word_size_bits;

    assign word_size_bits = word_size ? 5'd0 : 5'd16; 
    assign word_size_bits_minus_one = word_size_bits - 'h1;
    assign data_req = ~word_bit_count[3];

	assign sd = tx_reg[15];
    assign sck_out = (state == STATE_XFER) ? sck_in : 1'b1;

    always @(negedge sck_in or negedge rst_n) begin
        if (~rst_n) begin
            state <= STATE_IDLE;
            tx_reg <= 'd0;
            ws <= 1'b0; 
            word_bit_count <= 'h0;
        end else begin
            state <= next_state;
            tx_reg <= next_tx_reg;
            ws <= next_ws;
            word_bit_count <= next_word_bit_count;
        end
    end

    always @(*) begin
        next_state = state;
        next_tx_reg = tx_reg;
        next_ws = ws;
        next_word_bit_count = word_bit_count;
        case (state)
        STATE_IDLE: begin
            if (~start_n) begin
                next_state = STATE_WAIT; 
                next_ws = 1'b0;
            end
        end
        STATE_WAIT: begin // Preload data
            next_word_bit_count = word_bit_count + 'h1;
            if (next_word_bit_count[3:0] == 'h0) begin
                next_state = STATE_XFER;
                next_word_bit_count = 'h0;
                next_tx_reg = data_in;
            end
        end
        STATE_XFER: begin
            next_word_bit_count = word_bit_count + 'h1;
            next_tx_reg = tx_reg << 'h1;
            if (next_word_bit_count[3:0] == 'h0) 
                next_tx_reg = data_in;
            if (next_word_bit_count == word_size_bits) begin
                next_word_bit_count = 'h0;
                if (~stop_n)
                    next_state = STATE_IDLE;
            end
            if (next_word_bit_count == word_size_bits_minus_one) begin
                next_ws = ~ws;
            end
        end
        endcase
    end

endmodule