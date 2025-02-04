module freq_doubler(
    input  in,
    output out);

    wire delay;

    delay_line #(
        .STAGE_COUNT(8)) delay_line_inst(
        .in(in),
        .out(delay));

    xor xor_inst(out, in, delay);

endmodule