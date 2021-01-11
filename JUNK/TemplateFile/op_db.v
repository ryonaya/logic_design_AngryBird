module onepulse(s_op, s, clk);
	input s, clk;
	output reg s_op;
	reg s_delay;
	always@(posedge clk)begin
		s_op <= s&(!s_delay);
		s_delay <= s;
	end
endmodule

module debounce(s_db, s, clk);
	input s, clk;
	output s_db;
	reg [3:0] DFF;
	
	always@(posedge clk)begin
		DFF[3:1] <= DFF[2:0];
		DFF[0] <= s;
	end
	assign s_db = (DFF == 4'b1111)? 1'b1 : 1'b0;
endmodule

module collide_onepulse(s_op, s, clk, clk_25MHz, vsync);
	input [4-1:0] s;
    input clk, clk_25MHz, vsync;
	output reg [4-1:0] s_op;
    reg [4-1:0] s_op_i;
	reg [4-1:0] s_delay;
	always @(posedge clk) begin
        if(clk_25MHz) begin
            s_op_i <= s&(!s_delay);
		    s_delay <= s;
        end
        else begin
            s_op_i <= s_op_i;
		    s_delay <= s_delay;
        end
	end

    always @(posedge clk) begin
        if(|s_op_i)
            s_op <= s_op_i;
        else if(vsync)
            s_op <= 0;
        else 
            s_op <= s_op;
    end
endmodule