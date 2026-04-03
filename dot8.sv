/*******************************************************/
/* ECE 327/627: Digital Hardware Systems - Winter 2026 */
/* Lab 4                                               */
/* 8-Lane Dot Product Module                           */
/*******************************************************/

module dot8 # (
    parameter IWIDTH = 8,
    parameter OWIDTH = 32
)(
    input clk,
    input rst,
    input signed [8*IWIDTH-1:0] vec0,
    input signed [8*IWIDTH-1:0] vec1,
    input ivalid,
    output signed [OWIDTH-1:0] result,
    output ovalid
);

/******* Your code starts here *******/

logic signed [IWIDTH*8-1:0] a;
logic signed [IWIDTH*8-1:0] b;
logic signed [IWIDTH*2-1:0] products [0:7];
logic signed [IWIDTH*2:0] sum1 [0:3];
logic signed [IWIDTH*2+1:0] sum2[0:1];
logic signed [IWIDTH*2+2:0] sum3;
  
logic valid_s [4:0];

  
int j;



always_ff @(posedge clk) begin
  if (rst) begin
    valid_s[0] <= 1'b0;
    valid_s[1] <= 1'b0;
    valid_s[3] <= 1'b0;
    valid_s[4] <= 1'b0;
    valid_s[5] <= 1'b0;
    a <= '0;
    b <= '0;
    for (j =  0; j < 8; j++) begin
      products[j] <= '0;
    end
  end else begin
    valid_s[0] <= ivalid;
    valid_s[1] <= valid_s[0];
    valid_s[2] <= valid_s[1];
    valid_s[3] <= valid_s[2];
    valid_s[4] <= valid_s[3];
    a <= vec0;
    b <= vec1;
      
      
    for (j = 0; j < 8; j++)
      products[j] <= $signed(a[j*IWIDTH +: IWIDTH]) * $signed(b[j*IWIDTH +: IWIDTH]);
    
      
    sum1[0] <= products[0] + products[1];
    sum1[1] <= products[2] + products[3];
    sum1[2] <= products[4] + products[5];
    sum1[3] <= products[6] + products[7];
    
    sum2[0] <= sum1[0] + sum1[1];
    sum2[1] <= sum1[2] + sum1[3];
    
    sum3 <= sum2[0] + sum2[1];
    
   end
end
  
assign ovalid = valid_s[4];
assign result = sum3;

    
   

/******* Your code ends here ********/

endmodule
