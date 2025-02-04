module pulse_extender #(parameter
    WIDTH)(
    input          rst_n,
    input          clk,
    input          in,
    output         out);

    localparam STATE_IDLE  = 1'b0;
    localparam STATE_COUNT = 1'b1;

    reg             state, next_state;
    reg[WIDTH-1:0]  count, next_count;
    wire[WIDTH-1:0] count_plus_one;

    assign out = (state == STATE_COUNT) | in;
    assign count_plus_one = count + 1'h1;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= STATE_IDLE;
            count <= 'd0;
        end else begin
            state <= next_state;
            count <= next_count;
        end
    end

    always @(*) begin
        next_state = state;
        next_count = count;
        case (state)
        STATE_IDLE: begin
            if (in) begin
                next_state = STATE_COUNT;
                next_count = 'd1;
            end
        end 
        STATE_COUNT: begin
            next_count = count_plus_one;
            if (count_plus_one == 'd0) 
                next_state = STATE_IDLE;
        end
        endcase
    end

endmodule