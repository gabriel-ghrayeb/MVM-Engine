/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Winter 2026 */
/* Lab 4                                               */
/* Accumulator Module                                  */
/*******************************************************/

module accum # (
    parameter DATAW = 32,
    parameter ACCUMW = 32
)(
    input  clk,
    input  rst,
    input  signed [DATAW-1:0] data,
    input  ivalid,
    input  first,
    input  last,
    output signed [ACCUMW-1:0] result,
    output ovalid
);

logic signed [ACCUMW-1:0] accum_reg;
logic ovalidr;
always_ff @(posedge clk) begin
	if (rst) begin
		accum_reg <= '0;
		ovalidr <= 1'b0;
	end else begin
		ovalidr <= 1'b0;
		
		if (ivalid) begin
			accum_reg <= first ? ACCUMW'(signed'(data)) : accum_reg + ACCUMW'(signed'(data));
			ovalidr <= last;
		end
	end
end

assign ovalid = ovalidr;
assign result = accum_reg;



endmodule
