// -----------------------------------
// I2C interface; write only
// -----------------------------------
module i2c_if #(parameter
    DEV_ADDR = 8'h69,
	REG_ADDR_WIDTH = 3)(
    input                          rst_n,
    input                          clk,

    input                          scl,
    inout                          sda,

    // To register file 
    output reg[REG_ADDR_WIDTH-1:0] addr,
    output reg[7:0]                data,
    output                         write_req);

    localparam STATE_IDLE               = 3'd0;
    localparam STATE_WAIT               = 3'd1;
    localparam STATE_DEV_ADDR           = 3'd2;
    localparam STATE_DEV_ADDR_NOT_MATCH = 3'd3;
    localparam STATE_REG_ADDR           = 3'd4;
    localparam STATE_RX_DATA            = 3'd5;

    reg[2:0]                       state, next_state;
    reg[7:0]                       rx_reg, next_rx_reg;
    reg[2:0]                       rx_count, next_rx_count;
    reg[REG_ADDR_WIDTH-1:0]        next_addr;
    reg                            write_req_reg, next_write_req_reg;
    reg[7:0]                       next_data; 
    reg                            ack, next_ack;

    wire                           start_cond, stop_cond;
    wire                           sda_edge;
    wire                           scl_fall;
    wire[2:0]                      rx_count_plus_one;
    wire[7:0]                      rx_reg_shift_one;

    dual_edge_det sda_edge_det(
        .rst_n(rst_n),
        .clk(clk),
        .in(sda),
        .out(sda_edge));
    
    pos_edge_det scl_edge_det(
        .rst_n(rst_n),
        .clk(clk),
        .in(~scl), // falling edge
        .out(scl_fall));

    dual_edge_det write_req_det(
        .rst_n(rst_n),
        .clk(clk),
        .in(write_req_reg),
        .out(write_req));

    assign sda        = ack ? 1'b0 : 1'bz;
    assign start_cond = sda_edge & ~sda & scl; // sda fall when scl high
    assign stop_cond  = sda_edge & sda & scl;  // sda rise when scl high
    assign rx_count_plus_one = rx_count + 'h1;
    assign rx_reg_shift_one = (rx_reg << 'h1) | sda;
	 
	initial begin
        state <= STATE_IDLE;
        ack <= 1'b0;
	end

    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= STATE_IDLE;
            addr <= 'h0;
            data <= 'h0;
            write_req_reg <= 'h0;
            rx_reg <= 'h0;
            rx_count <= 'h0;
            ack <= 1'b0;
        end else begin
            state <= next_state;
            addr <= next_addr;
            data <= next_data;
            write_req_reg <= next_write_req_reg;
            rx_reg <= next_rx_reg;
            rx_count <= next_rx_count;
            ack <= next_ack;
        end
    end

    always @(*) begin
        next_state = state;
        next_addr = addr;
        next_rx_reg = rx_reg;
        next_rx_count = rx_count;
        next_data = data;
        next_write_req_reg = write_req_reg;
        next_ack = ack;
        case (state) 
        STATE_IDLE: begin
            if (start_cond) 
                next_state = STATE_WAIT;
        end
        STATE_WAIT: begin
            if (scl_fall) 
                next_state = STATE_DEV_ADDR;
        end
        STATE_DEV_ADDR: begin
            if (scl_fall) begin
                if (~ack) begin
                    next_rx_reg = rx_reg_shift_one;
                    next_rx_count = rx_count_plus_one;
                    if (next_rx_count == 'h0) begin                 // Got device addr
                        if (next_rx_reg == (DEV_ADDR << 'h1)) begin // Device addr match
                            next_ack = 1'b1;
                        end else begin                              // Device addr not match
                            next_state = STATE_DEV_ADDR_NOT_MATCH;
                        end
                    end
                end else begin
                    next_ack = 1'b0;
                    next_state = STATE_REG_ADDR;
                end
            end
        end
        STATE_DEV_ADDR_NOT_MATCH: begin
            if (stop_cond) 
                next_state = STATE_IDLE;
        end
        STATE_REG_ADDR: begin
            if (scl_fall) begin
                if (~ack) begin
                    next_rx_reg = rx_reg_shift_one;
                    next_rx_count = rx_count_plus_one;
                    if (next_rx_count == 'h0) begin              // Got reg addr
                        next_addr = next_rx_reg - 'h1;           // minus one to align with data
                        next_ack = 1'b1;
                    end
                end else begin
                    next_ack = 1'b0;
                    next_state = STATE_RX_DATA;
                end
            end
        end
        STATE_RX_DATA: begin
            if (scl_fall) begin
                if (~ack) begin
                    next_rx_reg = rx_reg_shift_one;
                    next_rx_count = rx_count_plus_one;
                    if (next_rx_count == 'h0) begin
                        next_data = next_rx_reg;
                        next_addr = addr + 'h1; 
                        next_ack = 1'b1;
                    end
                end else begin
                    next_ack = 1'b0;
                    next_write_req_reg = ~next_write_req_reg;  // write data to register file
                end
            end else if (stop_cond) begin
                next_state = STATE_IDLE;
            end
        end
        endcase
    end

endmodule