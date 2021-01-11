module clock_divisor(
    input clk, 
    output clk1
);
reg  [2-1:0] num;
wire [2-1:0] next_num;

always @(posedge clk) begin
  num <= next_num;
end

assign next_num = num + 1'b1;
assign clk1 = num[1];
endmodule
