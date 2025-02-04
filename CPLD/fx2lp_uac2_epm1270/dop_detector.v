// -----------------------------------
// DoP detector
// 
// Pattern: 
// ------------------
// Word | Data
// -1   | xx       xx
// 0    | MARKER_0 xx 
// 1    | xx       xx
// 2    | MARKER_0 xx
// 3    | xx       xx
// 4    | MARKER_1 xx
// 5    | xx       xx
// 6    | MARKER_1 xx
// 7    | xx       xx
// 8    | MARKER_0 xx 
// 9    | xx       xx
// ...
// -----------------------------------
module dop_detector #(parameter
    DOP_MARKER_0 = 8'h05,
    DOP_MARKER_1 = 8'hfa,
    MATCH_COUNT = 5'd16)(
    input       rst_n,
    input       clk,

    input[15:0] data,
    input       data_valid,
    
    output reg  success,
    input       clear_success_n);

    localparam STATE_MARKER_0_0 = 4'd0;
    localparam STATE_SKIP_0_0   = 4'd1;
    localparam STATE_MARKER_0_1 = 4'd2;
    localparam STATE_SKIP_0_1   = 4'd3;
    localparam STATE_MARKER_1_0 = 4'd4;
    localparam STATE_SKIP_1_0   = 4'd5;
    localparam STATE_MARKER_1_1 = 4'd6;
    localparam STATE_SKIP_1_1   = 4'd7;
    localparam STATE_SUCCESS    = 4'd8;

    reg[3:0] state, next_state;
    reg[4:0] match_count, next_match_count;
    reg      next_success;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= STATE_MARKER_0_0;
            match_count <= 'd0;
            success <= 1'b0;
        end else begin
            state <= next_state;
            match_count <= next_match_count;
            success <= next_success;
        end
    end

    always @(*) begin
        next_state = state;
        next_match_count = match_count;
        next_success = success;
        case (state) 
        STATE_MARKER_0_0: begin
            if (data_valid) begin
                if (data[15:8] == DOP_MARKER_0) begin
                    next_state = STATE_SKIP_0_0;
                end else begin
                    next_state = STATE_MARKER_0_0;
                    next_match_count = 'd0;
                end
            end
        end
        STATE_SKIP_0_0: begin
            if (data_valid) begin
                next_state = STATE_MARKER_0_1;
            end
        end
        STATE_MARKER_0_1: begin
            if (data_valid) begin
                if (data[15:8] == DOP_MARKER_0) begin
                    next_state = STATE_SKIP_0_1;
                end else begin
                    next_state = STATE_MARKER_0_0;
                    next_match_count = 'd0;
                end
            end
        end
        STATE_SKIP_0_1: begin
            if (data_valid) begin
                next_state = STATE_MARKER_1_0;
            end 
        end
        STATE_MARKER_1_0: begin
            if (data_valid) begin
                if (data[15:8] == DOP_MARKER_1) begin
                    next_state = STATE_SKIP_1_0;
                end else begin
                    next_state = STATE_MARKER_0_0;
                    next_match_count = 'd0;
                end
            end
        end
        STATE_SKIP_1_0: begin
            if (data_valid) begin
                next_state = STATE_MARKER_1_1;
            end
        end
        STATE_MARKER_1_1: begin
            if (data_valid) begin
                if (data[15:8] == DOP_MARKER_1) begin
                    next_match_count = match_count + 'd1;
                    if (next_match_count == MATCH_COUNT) begin // DoP stream detected
                        next_state = STATE_SUCCESS;
                        next_match_count = 'd0;
                        next_success = 1'b1;
                    end else begin
                        next_state = STATE_SKIP_1_1;
                    end
                end else begin
                    next_state = STATE_MARKER_0_0;
                    next_match_count = 'd0;
                end
            end
        end
        STATE_SKIP_1_1: begin
            if (data_valid) begin
                next_state = STATE_MARKER_0_0;
            end
        end
        STATE_SUCCESS: begin
            if (~clear_success_n) begin
                next_state = STATE_MARKER_0_0;
                next_success = 1'b0;
            end
        end
        endcase
    end

endmodule