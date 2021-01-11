// <summary>
// Signed add/minus operation for 16 bits with overflow prevention 
// </summary>
module sa (
    input [17-1:0] a_i, b_i,
    output [17-1:0] sum_o
    );
    
    wire [18-1:0] sum_t;
    assign sum_t = {a_i[16], a_i} + {b_i[16], b_i};
    assign sum_o = (~sum_t[17] &  sum_t[16]) ? 17'b0_1111_1111_1111_1111 : // + overflow
                   ( sum_t[17] & ~sum_t[16]) ? 17'b1_0000_0000_0000_0000 : // - overflow
                   sum_t[16:0];
endmodule