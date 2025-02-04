//--------------------------------------------
// Interface with FX2
// NOTE: 
// By EZ-USB USER MANUAL Pg.63, external interrupts must be held 
// long enough to be detected.
// do_write has higher priority than do_read, therefore, whenever do_write is asserted, it is 
// immediately served. After which the reading will continue. The transition state leaves read and write one
// ifclk cycle seperated.
//--------------------------------------------
module fx2_if(
	// FX2 signals
	input              rst_n,
	input              ifclk,
	inout[15:0]        fd,
	input              read_ef_n,

	output[1:0]        fifoadr,
	output             slrd_n,
	output             slwr_n, 
	output             sloe_n,

	input              write_req,
	output             write_done,
	
	// Data out
	output[15:0]       data_out,
	output             data_out_valid,
	
	// Data in
	input[15:0]        data_in);

	localparam STATE_IDLE = 'd0;
	localparam STATE_READ = 'd1;
	localparam STATE_TRANSITION = 'd2;
	localparam STATE_WRITE = 'd3;

	localparam READ_FIFOADR  = 2'b00; // EP2
	localparam WRITE_FIFOADR = 2'b11; // EP8

	reg[1:0]           state, next_state;
	reg                write_done_pulse, next_write_done_pulse;

	wire               do_write;
	wire               do_read;

	// 8 cycles
	pulse_extender #(.WIDTH('d3)) 
	write_done_ext(
		.rst_n(rst_n),
		.clk(ifclk),
		.in(write_done_pulse),
		.out(write_done));

	dual_edge_det write_req_det(
		.rst_n(rst_n),
		.clk(ifclk),
		.in(write_req),
		.out(do_write));

	assign do_read = read_ef_n & ~do_write;
	assign slrd_n = ~((state == STATE_READ) & do_read);
	assign slwr_n = ~(state == STATE_WRITE);
	assign sloe_n = slrd_n;
	assign fifoadr = (state == STATE_WRITE) ? WRITE_FIFOADR :
	                 (state == STATE_READ)  ? READ_FIFOADR  : 2'hz;
	assign fd = ~slwr_n ? data_in : 16'hz;
	assign data_out = fd;
	assign data_out_valid = ~slrd_n;
	
	always @(posedge ifclk or negedge rst_n) begin
		if (~rst_n) begin
			state <= STATE_IDLE;
			write_done_pulse <= 1'b0;
		end else begin
			state <= next_state;
			write_done_pulse <= next_write_done_pulse;
		end
	end

	always @(*) begin
		next_state = state;
		next_write_done_pulse = write_done_pulse;
		case (state) 
		STATE_IDLE: begin
			next_write_done_pulse = 1'b0;
			if (do_write) begin
				next_state = STATE_WRITE;
			end else if (do_read) begin
				next_state = STATE_READ;
			end
		end
		STATE_READ: begin
			if (do_write) begin
				next_state = STATE_TRANSITION;
			end else if (~do_read) begin
				next_state = STATE_IDLE;
			end
		end
		STATE_TRANSITION: begin 
			next_state = STATE_WRITE;
		end
		STATE_WRITE: begin
			next_state = STATE_IDLE;
			next_write_done_pulse = 1'b1;
		end
		endcase
	end

endmodule