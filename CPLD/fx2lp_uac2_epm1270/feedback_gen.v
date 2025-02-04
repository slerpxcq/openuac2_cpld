// ------------------------------------
// Feedback value generator
//
// Measures how many ifclk cycles is half_n asserted in one SOF
// ------------------------------------

module feedback_gen(
    input            rst_n,
    input            clk,

    input            reset,
    input            half_n,

    output reg[15:0] count);

    reg[15:0] next_count;
    wire      do_reset;

    pos_edge_det reset_edge_det(
        .rst_n(rst_n),
        .clk(clk),
        .in(reset),
        .out(do_reset));

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            count <= 16'd0;
        end else begin
            count <= next_count;
        end
    end

    always @(*) begin
        next_count = count;
        if (do_reset) begin
            next_count = 0;
        end else if (~half_n) begin
            next_count = count + 16'd1;
        end
    end

endmodule