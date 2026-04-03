/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Winter 2026 */
/* Lab 4                                               */
/* Matrix Vector Multiplication (MVM) Module           */
/*******************************************************/

module mvm # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32,
    parameter MEM_DATAW = IWIDTH * 8,
    parameter VEC_MEM_DEPTH = 256,
    parameter VEC_ADDRW = $clog2(VEC_MEM_DEPTH),
    parameter MAT_MEM_DEPTH = 512,
    parameter MAT_ADDRW = $clog2(MAT_MEM_DEPTH),
    parameter NUM_OLANES = 64
)(
    input clk,
    input rst,
    input [MEM_DATAW-1:0] i_vec_wdata,
    input [VEC_ADDRW-1:0] i_vec_waddr,
    input i_vec_wen,
    input [MEM_DATAW-1:0] i_mat_wdata,
    input [MAT_ADDRW-1:0] i_mat_waddr,
    input [NUM_OLANES-1:0] i_mat_wen,
    input i_start,
    input [VEC_ADDRW-1:0] i_vec_start_addr,
    input [VEC_ADDRW:0] i_vec_num_words,
    input [MAT_ADDRW-1:0] i_mat_start_addr,
    input [MAT_ADDRW:0] i_mat_num_rows_per_olane,
    output o_busy,
    output [OWIDTH*NUM_OLANES-1:0] o_result,
    output o_valid
);

logic [VEC_ADDRW-1:0] vec_raddr;
logic [MAT_ADDRW-1:0] mat_raddr;
logic ctrl_ovalid;
logic ctrl_first;
logic ctrl_last;

logic [MEM_DATAW-1:0] vec_rdata;
logic [MEM_DATAW-1:0] mat_rdata [NUM_OLANES];

logic signed [OWIDTH-1:0] dot8_result [NUM_OLANES];
logic dot8_ovalid [NUM_OLANES];

logic [OWIDTH-1:0] accum_result [NUM_OLANES];
logic accum_ovalid [NUM_OLANES];


ctrl #(
	.VEC_ADDRW (VEC_ADDRW),
	.MAT_ADDRW (MAT_ADDRW),
  	.VEC_SIZEW (VEC_ADDRW + 1),
	.MAT_SIZEW (MAT_ADDRW + 1)
) u_ctrl (
	.clk (clk),
        .rst (rst),
        .start (i_start),
        .vec_start_addr (i_vec_start_addr),
        .vec_num_words (i_vec_num_words),
        .mat_start_addr (i_mat_start_addr),
        .mat_num_rows_per_olane (i_mat_num_rows_per_olane),
  		.vec_raddr (vec_raddr),
  		.mat_raddr (mat_raddr),
        .accum_first (ctrl_first),
        .accum_last (ctrl_last),
        .ovalid (ctrl_ovalid),
        .busy (o_busy)
);

mem #(
	.DATAW (MEM_DATAW),
	.DEPTH (VEC_MEM_DEPTH)
) u_vec_mem (
	.clk (clk),
	.waddr (i_vec_waddr),
	.wdata (i_vec_wdata),
	.wen (i_vec_wen),
	.raddr (vec_raddr),
	.rdata (vec_rdata)
);

genvar i;
generate 
	for (i = 0; i < NUM_OLANES; i = i + 1) begin : gen_lane
		mem #(
			.DATAW (MEM_DATAW),
			.DEPTH (MAT_MEM_DEPTH)
		) u_mat_mem (
			.clk (clk),
			.waddr (i_mat_waddr),
			.wdata (i_mat_wdata),
			.wen (i_mat_wen[i]),
			.rdata (mat_rdata[i]),
			.raddr (mat_raddr)
		);
		
		dot8 #(
			.IWIDTH (IWIDTH),
			.OWIDTH (OWIDTH)
		) u_dot8 (
			.clk (clk),
			.rst (rst),
			.vec0 (vec_rdata),
			.vec1 (mat_rdata[i]),
			.result (dot8_result[i]),
			.ovalid (dot8_ovalid[i]),
			.ivalid (ctrl_ovalid)
		);

		accum #(	
			.DATAW (OWIDTH),
			.ACCUMW (OWIDTH)
		) u_accum (
			.clk (clk),
			.rst (rst),
			.data (dot8_result[i]),
			.ivalid (dot8_ovalid[i]),
			.result (accum_result[i]),
			.ovalid (accum_ovalid[i]),
			.first (ctrl_first),
			.last (ctrl_last)
		);
		
		assign o_result[OWIDTH*(i+1)-1:OWIDTH*i] = accum_result[i];
end
endgenerate

assign o_valid = accum_ovalid[NUM_OLANES-1];



endmodule