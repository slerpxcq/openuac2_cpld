module pos_edge_det(
    input  rst_n,
    input  clk,
    input  in,
    output out);

    reg    q0, q1;

    assign out = q0 & ~q1;

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            q0 <= 1'b0;
            q1 <= 1'b0;
        end else begin
            q0 <= in;
            q1 <= q0;
        end
    end

endmodule