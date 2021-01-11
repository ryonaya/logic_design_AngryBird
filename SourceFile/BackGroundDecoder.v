module bg_pixel_decode(
    input  [5-1:0]  pre_bg_pixel,
    output [12-1:0] bg_pixel
);

parameter [12-1:0] list [0:28] = {
    12'hCEE,
    12'hCEF,
    12'hCE7,
    12'hAC8,
    12'h7A7,
    12'hFFA,
    12'hFFB,
    12'hDEF,
    12'hDFF,
    12'hDEA,
    12'hBD9,
    12'h9B7,
    12'hEFC,
    12'hDEB,
    12'hEFF,
    12'hFFF,
    12'hFFE,
    12'hFFC,
    12'hBE5,
    12'h9C5,
    12'h8A7,
    12'h795,
    12'h793,
    12'h673,
    12'h562,
    12'h452,
    12'h121,
    12'h231,
    12'h232
};

assign bg_pixel = list[pre_bg_pixel];

endmodule

module menu_pixel_decode(
    input  [5-1:0]  pre_menu_pixel,
    output [12-1:0] menu_pixel
);

parameter [12-1:0] list [0:30] = {
    12'h9CD,
    12'h8AB,
    12'h789,
    12'h577,
    12'h455,
    12'h9AA,
    12'hCDD,
    12'hBBC,
    12'hEFF,
    12'hFFF,
    12'hDEE,
    12'hEEC,
    12'h126,
    12'hABD,
    12'h241,
    12'hADE,
    12'hCDE,
    12'hDEF,
    12'hDFF,
    12'hBCF,
    12'hFEA,
    12'hFE5,
    12'hEB2,
    12'hEC7,
    12'hC71,
    12'h7A5,
    12'h361,
    12'h490,
    12'h6B0,
    12'h8C0,
    12'h014 
};
assign menu_pixel = list[pre_menu_pixel];

endmodule