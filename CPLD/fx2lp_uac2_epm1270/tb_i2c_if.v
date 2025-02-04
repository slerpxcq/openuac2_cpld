`timescale 1ns/1ps

module tb_i2c_if;
    // device signals
    reg            rst_n;
    reg            clk;
    reg            scl;
    wire           sda;
    wire[3:0]      reg_addr;
    wire[7:0]      reg_data;
    wire           reg_write_req;

    // internal signal
    reg            sda_reg;
    reg[7:0]       write_data;
    reg[7:0]       write_data_reg;
    reg            wait_ack;

    i2c_if dut(
        .rst_n(rst_n),
        .clk(clk),
        .scl(scl),
        .sda(sda),
        .addr(reg_addr),
        .data(reg_data),
        .write_req(reg_write_req));

    assign sda = wait_ack ? 1'bz : sda_reg;
    
    always #2 clk = ~clk;

    initial begin
        sda_reg = 1;
        write_data = 8'h69 << 1; 
        write_data_reg = 7;
        wait_ack = 0;
        clk = 1;
        rst_n = 1;
        scl = 1;
        #1 rst_n = 0;
        #1 rst_n = 1;

        // -----------------------------------
        // start condition
        // -----------------------------------
        #100 sda_reg = 0;
        #20 scl = 0;

        // -----------------------------------
        // send device addr
        // -----------------------------------
        repeat (8) begin
            sda_reg = write_data[7];
            #20 scl = 1;
            #20 scl = 0;
            #20 write_data = write_data << 1;
        end
        // check ack
        wait_ack = 1;
        #20 scl = 1;
        #20 scl = 0;
        wait_ack = 0;

        // -----------------------------------
        // send register addr
        // -----------------------------------
        write_data = 8'h37;
        repeat (8) begin
            sda_reg = write_data[7];
            #20 scl = 1;
            #20 scl = 0;
            #20 write_data = write_data << 1;
        end
        // check ack
        wait_ack = 1;
        #20 scl = 1;
        #20 scl = 0;
        wait_ack = 0;

        // -----------------------------------
        // send 4 data 
        // -----------------------------------
        write_data_reg = 3;
        repeat (4) begin
            write_data = write_data_reg;
            write_data_reg = write_data_reg + 1;
            repeat (8) begin
                sda_reg = write_data[7];
                #20 scl = 1;
                #20 scl = 0;
                #20 write_data = write_data << 1;
            end
            // check ack
            wait_ack = 1;
            #20 scl = 1;
            #20 scl = 0;
            wait_ack = 0;
        end

        // -----------------------------------
        // stop condition
        // -----------------------------------
        #20 scl = 1;
        #20 sda_reg = 1;
        #500 $stop;
    end

endmodule