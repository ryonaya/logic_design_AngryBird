// <summary>
// A Slingshot Object that generates drawing information
// </summary>
module slingshot(
    // Basic input      
    input [10-1:0] h_cnt, v_cnt,

    // position output
    output slingshot,
    output [12-1:0] slingshot_pixel_addr
);

    wire [10-1:0] x1, x2, y1, y2;

    assign x1 = 10'd101;
    assign y1 = 10'd325;
    assign x2 = 10'd130;
    assign y2 = 10'd411;
    assign slingshot = ( (h_cnt >= x1 && h_cnt <= x2) && (v_cnt >= y1 && v_cnt <= y2) ) ? 1 : 0;
    assign slingshot_pixel_addr = (h_cnt-x1) + ((v_cnt-y1) * 30);

endmodule

