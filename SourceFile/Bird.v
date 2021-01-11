// <summary>
// A bird Object with position data and force calculation.
// </summary>
module bird #(
    H_SIZE=10'd16,      // hitbox radius        // Circular hitbox ??
                                            // maybe using two (or more) long rectangles to approach ??
    IX=10'd100,         // Initial horizontal position of square centre
    IY=10'd100,         // Initial vertical position of square centre
    NUM=3'b0,          // Index of this bird
    D_WIDTH=10'd640,    // Width of display
    D_HEIGHT=10'd480    // Height of display
)(
    /// Basic input
    input clk,
    input vsync, vsync2,                    // One-pulse, active-high, trigger once a frame.
    input rst,       
    input [10-1:0] h_cnt, v_cnt,

    /// force and control input      
    input [3-1:0] macro_state, 
    input [2-1:0] state,
    input [10-1:0] cnt,             // Bird behaviour timer
    input pulse_en,                 // Enable "Force to Velocity" calculation, should hold for a frame
    input signed [17-1:0] deltaX, deltaY,  // F = -k * deltaX
    input signed [17-1:0] bird_force_x, bird_force_y,

    /// position output
    output reg [17-1:0] vx, vy,
    output bird,
    output [10-1:0] bird_pixel_addr,
    output [4-1:0]  bird_dir
);

    /// Bird pixel mask
    localparam [0:1023] bird_mask = {
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 
        1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 
        1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 
        1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0
    };
    /// Macro State
    localparam NONE   = 3'd7,                // Determine which is the Main Bird.
              BIRD_0 = 3'd0,                
              BIRD_1 = 3'd1,                // All the bird before BIRD_N should hold their pos,
              BIRD_2 = 3'd2;                //      but still need to be able to react to collision.

    /// State                               // Use (x1, y1) for more easier reco, not (x, y)
    localparam WAIT_FOR_LOAD = 2'd0,         // ALL Active Bird should hold their position (x1 = (32*n) , y1 = 380).
              LOADING_ANIM  = 2'd1,         // Main Bird on interpolation of (64, 380) -> (100, 325). Others move to (x + 32, 380).
              WAIT_FOR_SHOT = 2'd2,         // Main Bird should on (100, 325).
              FLYING        = 2'd3;         // Main Bird should fly to random place, and then change state to WAIT_FOR_LOAD.
    /// Bird_Loading animation position list
    localparam [10-1:0] anim_list_x [0:32-1] = {
        10'd81,         10'd83,     // Fast phase
        10'd84,         10'd86,
        10'd87,         10'd89,
        10'd90,         10'd92,
        10'd93,         10'd94,
        10'd95,         10'd96,     

        10'd97,         10'd98,     // Symmetrical_Up phase
        10'd99,         10'd100,
        10'd101,        10'd102,
        10'd103,        10'd104,
        10'd105,        10'd106,

        10'd107,        10'd108,    // Symmetrical_Down phase
        10'd109,        10'd110,
        10'd111,        10'd112,
        10'd113,        10'd114,
        10'd115,        10'd116
    };
    localparam [10-1:0] anim_list_y [0:32-1] = {
        10'd389,        10'd383,    // Fast phase
        10'd377,        10'd372,
        10'd367,        10'd362,
        10'd358,        10'd354,
        10'd350,        10'd346,
        10'd342,        10'd339,

        10'd336,        10'd333,    // Symmetrical_Up phase
        10'd331,        10'd329,
        10'd327,        10'd325,
        10'd324,        10'd323,
        10'd322,        10'd321,

        10'd321,        10'd322,    // Symmetrical_Down phase
        10'd323,        10'd324,
        10'd325,        10'd327,
        10'd330,        10'd333,
        10'd336,        10'd341
    };


    /// Position declaration
    localparam GRAVITY = 17'd2;          // Gravity > 0 since y-axis points down
    wire        [10-1:0] x, y;
    wire        [17-1:0] nx, ny;        // 17 bits, 0 ~ 1023, with 6 bits of decimal part, and 1 bit of signed bit
    reg         [17-1:0] tmpx, tmpy;    // 17 bits, 0 ~ 1023, with 6 bits of decimal part, and 1 bit of signed bit
    wire signed [17-1:0] i_nvx, i_nvy; 
    wire signed [17-1:0] nvx, nvy;      // Defined as signed, since I need to use ">>> 1"

    /// Boundary declaration
    wire [10-1:0] x1, x2, y1, y2;       // 10 bits : 0 ~ 1023
    wire [10-1:0] bird_pixel_addr_pos;
    assign x1 = (x > H_SIZE) ? x - H_SIZE : 10'b0;
    assign y1 = (y > H_SIZE) ? y - H_SIZE : 10'b0;
    assign x2 = x1 + (H_SIZE<<1);
    assign y2 = y1 + (H_SIZE<<1);
    assign bird_pixel_addr_pos = (h_cnt-x1) + ((v_cnt-y1) << 5);
    assign bird = ( (h_cnt > x1 && h_cnt < x2) && 
                    (v_cnt > y1 && v_cnt < y2) && 
                    bird_mask[bird_pixel_addr_pos] == 1'b1 ) ? 1'b1 : 1'b0;
    assign bird_pixel_addr = bird ? bird_pixel_addr_pos : 10'b0;


    /// Collision signal
    assign bird_dir[3] = (h_cnt > x-8 && h_cnt < x+8) ? 1'b1 : 1'b0;
    assign bird_dir[2] = (v_cnt > y-8 && v_cnt < y+8) ? 1'b1 : 1'b0;
    assign bird_dir[1] = h_cnt > x ? 1'b1 : 1'b0;
    assign bird_dir[0] = v_cnt > y ? 1'b1 : 1'b0;
    //               (10)
    //    (x1, y1)          (x2, y1)        -> bird_pos(x, y)
    //      (00)   ┌------┐   (10)          -> bird_dir[1:0] (4 corner)
    //             | A  A |
    // (01)        |  __  |           (01)  -> bird_dir[3:2] (4 dir)
    //      (01)   └------┘   (11)
    //    (x1, y2)          (x2, y2)
    //               (10)
    /// Useful Signals
    wire [2:0] screen_border;
    wire onGround, onTop, onRight;
    assign onGround = (y2 >= 10'd412 ? 1'b1 : 1'b0);
    assign onTop    = (y1 == 10'd0   ? 1'b1 : 1'b0);
    assign onRight  = (x2 >= 10'd639 ? 1'b1 : 1'b0);
    assign screen_border = {(onGround & !vy[16]), (onTop & vy[16]), (onRight & !vx[16])};


    /// State Control
    wire main_bird;
    wire [2-1:0] my_action;
    assign main_bird = (macro_state == NUM) ? 1'b1 : 1'b0;

    reg pre_force;
    always @(posedge clk) begin
        if( ((|bird_force_x) | (|bird_force_y)) & vsync)
            pre_force <= 1;
        else if(vsync)
            pre_force <= 0;
        else 
            pre_force <= pre_force;
    end

    /// V, Combinational
    sa nvy_gravity(vy, GRAVITY, i_nvy);
    assign nvy = i_nvy  + (pre_force ? 0 : bird_force_y);
    assign nvx = vx     + (pre_force ? 0 : bird_force_x);

    /// V, Force, Sequential
    always @ (posedge clk) begin
        if (rst) begin
            vx <= 0;
            vy <= 0;
        end
        else if (vsync == 1) begin                              // update every frame  //
            case (state)                                    
                WAIT_FOR_SHOT   : begin
                    if(main_bird) begin
                        if(pulse_en == 1) begin
                            vx <= (-deltaX) <<< 1;
                            vy <= (-deltaY) <<< 2;
                        end
                        else begin
                            vx <= nvx;
                            vy <= nvy;
                        end
                    end
                    else if(macro_state > NUM) begin
                        case(screen_border) 
                        3'b100  : begin     // friction simulation // 
                            vx <= nvx>>>1;  // onGround
                            vy <= -(nvy>>>1);
                        end
                        3'b010  : begin     // onTop
                            vx <= nvx;
                            vy <= -(nvy);
                        end
                        3'b001  : begin     // onRight
                            vx <= -(nvx);
                            vy <= nvy;
                        end
                        default : begin
                            vx <= nvx;
                            vy <= nvy;
                        end
                        endcase
                    end
                    else begin
                        vx <= 0;
                        vy <= 0;
                    end
                end
                FLYING          : begin
                    if(main_bird) begin
                        case(screen_border) 
                        3'b100  : begin                                // friction simulation // 
                            vx <= nvx>>>1;                          // onGround
                            vy <= -(nvy>>>1);
                        end
                        3'b010  : begin    // onTop
                            vx <= nvx;
                            vy <= -(nvy);
                        end
                        3'b001  : begin    // onRight
                            vx <= -(nvx);
                            vy <= nvy;
                        end
                        default : begin
                            vx <= nvx;
                            vy <= nvy;
                        end
                        endcase
                    end
                    else begin
                        case(screen_border) 
                        3'b100  : begin     // friction simulation // 
                            vx <= nvx>>>1;  // onGround
                            vy <= -(nvy>>>1);
                        end
                        3'b010  : begin     // onTop
                            vx <= nvx;
                            vy <= -(nvy);
                        end
                        3'b001  : begin     // onRight
                            vx <= -(nvx);
                            vy <= nvy;
                        end
                        default : begin
                            vx <= nvx;
                            vy <= nvy;
                        end
                        endcase
                    end
                end
                default         : begin
                    case(screen_border) 
                    3'b100  : begin     // friction simulation // 
                        vx <= nvx>>>1;  // onGround
                        vy <= -(nvy>>>1);
                    end
                    3'b010  : begin     // onTop
                        vx <= nvx;
                        vy <= -(nvy);
                    end
                    3'b001  : begin     // onRight
                        vx <= -(nvx);
                        vy <= nvy;
                    end
                    default : begin
                        vx <= nvx;
                        vy <= nvy;
                    end
                    endcase
                end
            endcase
        end
        else begin                      // hold //
            vx <= vx;
            vy <= vy;
        end
    end


    /// X, Combinational
    sa nx_normal (tmpx, vx, nx);
    sa ny_normal (tmpy, vy, ny);

    /// X, Sequential
    always @ (posedge clk) begin
        if (rst) begin    
            tmpx <= IX<<6;
            tmpy <= IY<<6;
        end
        else if (vsync) begin      // update every frame //
            case (state)                // Using "state", not "my_action"
                // WAIT_FOR_LOAD   : begin
                //     tmpx <= tmpx;
                //     tmpy <= tmpy;
                // end
                LOADING_ANIM    : begin // Using pipeline and localparam list to create animation
                    if(main_bird) begin            // Main Bird follow loading route
                        tmpx <= (anim_list_x[cnt]<<6);                                          /////////////////////////////////////
                        tmpy <= (anim_list_y[cnt]<<6);
                    end
                    else if(macro_state < NUM) begin        // Other living birds just move to the right
                        tmpx <= tmpx + (1<<6);
                        tmpy <= tmpy;
                    end
                    else begin
                        tmpx <= nx;
                        tmpy <= ny;
                    end
                end
                WAIT_FOR_SHOT   : begin // (116, 341)
                    if(main_bird) begin            // Main Bird follow loading route
                        tmpx <= (10'd116 + deltaX)<<6;
                        tmpy <= (10'd341 + deltaY)<<6;
                    end
                    else begin
                        tmpx <= nx;
                        tmpy <= ny;
                    end
                end
                FLYING          : begin
                    if(macro_state >= NUM) begin
                        tmpx <= nx;
                        tmpy <= ny;
                    end
                    else begin
                        tmpx <= tmpx;
                        tmpy <= tmpy;
                    end
                end
                default         : begin
                    tmpx <= nx;
                    tmpy <= ny;
                end
            endcase
        end
        else begin                      // hold //
            tmpx <= tmpx;
            tmpy <= tmpy;
        end
    end
    assign x = tmpx[15:6];
    assign y = tmpy[15:6];              // Only 15~6, since 16 is signed bit

endmodule
