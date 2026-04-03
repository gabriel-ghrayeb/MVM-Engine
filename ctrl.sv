/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Winter 2026 */
/* Lab 4                                               */
/* MVM Control FSM                                     */
/*******************************************************/

module ctrl # (
    parameter VEC_ADDRW = 8,
    parameter MAT_ADDRW = 9,
    parameter VEC_SIZEW = VEC_ADDRW + 1,
    parameter MAT_SIZEW = MAT_ADDRW + 1
    
)(
    input  clk,
    input  rst,
    input  start,
    input  [VEC_ADDRW-1:0] vec_start_addr,
    input  [VEC_SIZEW-1:0] vec_num_words,
    input  [MAT_ADDRW-1:0] mat_start_addr,
    input  [MAT_SIZEW-1:0] mat_num_rows_per_olane,
    output [VEC_ADDRW-1:0] vec_raddr,
    output [MAT_ADDRW-1:0] mat_raddr,
    output accum_first,
    output accum_last,
    output ovalid,
    output busy
);

localparam PIPE_DEPTH = 6;
localparam DRAIN_CYCLES = PIPE_DEPTH + 1;

typedef enum logic {IDLE = 1'b0, COMPUTE = 1'b1} state_t;

state_t state;

logic [VEC_ADDRW-1:0] r_vec_start_addr;
logic [VEC_SIZEW-1:0] r_vec_num_words;
logic [MAT_ADDRW-1:0] r_mat_start_addr;
logic [MAT_SIZEW-1:0] r_mat_num_rows_per_olane;

logic [VEC_SIZEW-1:0] word_cnt;
logic [MAT_SIZEW-1:0] row_cnt;
logic [3:0] drain_cnt;
logic done;

logic [VEC_ADDRW-1:0] vec_raddr_r;
logic [MAT_ADDRW-1:0] mat_raddr_r;

logic r_ovalid, r_first, r_last;

logic [PIPE_DEPTH-1:0] first_sr, last_sr;

assign r_ovalid = (state == COMPUTE) && !done;
assign r_first = r_ovalid && (word_cnt == '0);
assign r_last = r_ovalid && (word_cnt == r_vec_num_words - 1);

always_ff @(posedge clk) begin
	if (rst) begin
		state <= IDLE;
		r_vec_start_addr <= '0;
            	r_vec_num_words  <= '0;
            	r_mat_start_addr <= '0;
            	r_mat_num_rows_per_olane <= '0;
            	word_cnt <= '0;
            	row_cnt <= '0;
            	drain_cnt <= '0;
            	done <= 1'b0;
            	vec_raddr_r <= '0;
            	mat_raddr_r <= '0;
	end else begin
		case (state)
			IDLE: begin
				r_vec_start_addr <= vec_start_addr;
                    		r_vec_num_words <= vec_num_words;
                    		r_mat_start_addr <= mat_start_addr;
                   		r_mat_num_rows_per_olane <= mat_num_rows_per_olane;
                    		vec_raddr_r <= '0;
                   		mat_raddr_r <= '0;
                    		done <= 1'b0;
				if (start) begin
					state <= COMPUTE;
					word_cnt <= '0;
					row_cnt <= '0;
					drain_cnt <= '0;
					vec_raddr_r <= vec_start_addr;
					mat_raddr_r <= mat_start_addr;
				end
			end
			
			COMPUTE: begin
				if (!done) begin
					if (word_cnt == r_vec_num_words - 1) begin
						word_cnt <= '0;
						vec_raddr_r <= r_vec_start_addr;
						if (row_cnt == r_mat_num_rows_per_olane - 1) begin
							done <= 1'b1;
							drain_cnt <= '0;
							row_cnt <= '0;
						end else begin
							row_cnt <= row_cnt +1;
							mat_raddr_r <= mat_raddr_r +1;
						end
					end else begin 
						word_cnt <= word_cnt + 1;
						vec_raddr_r <= vec_raddr_r + 1;
						mat_raddr_r <= mat_raddr_r + 1;
					end
				end else begin
					if (drain_cnt == DRAIN_CYCLES - 1)
						state <= IDLE;
					else
						drain_cnt <= drain_cnt +  1;
				end
			end	
			
			default: state <= IDLE;
		endcase
	end
end

logic ovalid_r;

always_ff @(posedge clk) begin
	if (rst) begin
		ovalid_r <= 1'b0;
		first_sr <= '0;
		last_sr <= '0;
	end else begin
		ovalid_r <= r_ovalid;
		first_sr <= {first_sr[PIPE_DEPTH-2:0], r_first};
		last_sr <= {last_sr[PIPE_DEPTH-2:0], r_last};
	end
end

assign vec_raddr = vec_raddr_r;
assign mat_raddr = mat_raddr_r;
assign ovalid = ovalid_r;
assign accum_first = first_sr[PIPE_DEPTH-1];
assign accum_last = last_sr[PIPE_DEPTH-1];
assign busy = (state == COMPUTE);

endmodule
