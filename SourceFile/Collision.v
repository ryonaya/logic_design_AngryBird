// <summary>
// 
// </summary>
module collision(
    // Basic Input      
    input clk,
    input rst,
    input vsync,

    // Main Input
    input [4-1:0]   collide,                 // {bird[2:0], pig}
    input [4*3-1:0] big_pre_bird_dir,
    input [4-1:0]   pre_pig_dir,
    input signed [17*3-1:0] big_bird_vx, big_bird_vy,
    input signed [17-1:0]   pig_vx,      pig_vy,

    // Output
    output [17*3-1:0] big_bird_force_x, big_bird_force_y,
    output reg [17-1:0] pig_force_x, pig_force_y
);
/*
7 0 1
6   2
5 4 3
*/


    // Main declare
    wire signed [17-1:0] bird_vx    [3-1:0], bird_vy   [3-1:0];
    wire [4-1:0]  pre_bird_dir      [3-1:0];
    reg [17-1:0] next_pig_force_x, next_pig_force_y;
    reg [17-1:0] next_bird_force_x  [3-1:0], next_bird_force_y  [3-1:0];
    reg [17-1:0] bird_force_x       [3-1:0], bird_force_y       [3-1:0];
    wire ooii, oioi, iooi, oiio, ioio, iioo;
    wire signed [17-1:0] abs_vx0, abs_vy0, abs_vx1, abs_vy1, abs_vx2, abs_vy2, abs_vxp, abs_vyp;

    assign abs_vx0 = ((bird_vx[0]^(bird_vx[0]>>>16))-(bird_vx[0]>>>16));
    assign abs_vy0 = ((bird_vy[0]^(bird_vy[0]>>>16))-(bird_vy[0]>>>16));
    assign abs_vx1 = ((bird_vx[1]^(bird_vx[1]>>>16))-(bird_vx[1]>>>16));
    assign abs_vy1 = ((bird_vy[1]^(bird_vy[1]>>>16))-(bird_vy[1]>>>16));
    assign abs_vx2 = ((bird_vx[2]^(bird_vx[2]>>>16))-(bird_vx[2]>>>16));
    assign abs_vy2 = ((bird_vy[2]^(bird_vy[2]>>>16))-(bird_vy[2]>>>16));
    assign abs_vxp = ((pig_vx^(pig_vx>>>16))-(pig_vx>>>16));
    assign abs_vyp = ((pig_vy^(pig_vy>>>16))-(pig_vy>>>16));

    assign ooii = ( abs_vx0 < 64 && abs_vy0 < 64 ) && ( abs_vxp < 64 && abs_vyp < 64 );
    assign oioi = ( abs_vx1 < 64 && abs_vy1 < 64 ) && ( abs_vxp < 64 && abs_vyp < 64 );
    assign iooi = ( abs_vx2 < 64 && abs_vy2 < 64 ) && ( abs_vxp < 64 && abs_vyp < 64 );
    assign oiio = ( abs_vx0 < 64 && abs_vy0 < 64 ) && ( abs_vx1 < 64 && abs_vy1 < 64 );
    assign ioio = ( abs_vx0 < 64 && abs_vy0 < 64 ) && ( abs_vx2 < 64 && abs_vy2 < 64 );
    assign iioo = ( abs_vx1 < 64 && abs_vy1 < 64 ) && ( abs_vx2 < 64 && abs_vy2 < 64 );

    /// input 1D to 2D
    assign bird_vx[0] = big_bird_vx[16:0];
    assign bird_vx[1] = big_bird_vx[33:17];
    assign bird_vx[2] = big_bird_vx[50:34];
    assign bird_vy[0] = big_bird_vy[16:0];
    assign bird_vy[1] = big_bird_vy[33:17];
    assign bird_vy[2] = big_bird_vy[50:34];
    assign pre_bird_dir[0] = big_pre_bird_dir[3:0];
    assign pre_bird_dir[1] = big_pre_bird_dir[7:4];
    assign pre_bird_dir[2] = big_pre_bird_dir[11:8];

    /// 2D to 1D output
    assign big_bird_force_x = {bird_force_x[2], bird_force_x[1], bird_force_x[0]};
    assign big_bird_force_y = {bird_force_y[2], bird_force_y[1], bird_force_y[0]};

    // Collision signal process
    wire [3-1:0] bird_dir   [3-1:0];
    wire [3-1:0] pig_dir;
    direction_decode cld_bird0 (.pre_dir(pre_bird_dir[0]), .dir(bird_dir[0]));
    direction_decode cld_bird1 (.pre_dir(pre_bird_dir[1]), .dir(bird_dir[1]));
    direction_decode cld_bird2 (.pre_dir(pre_bird_dir[2]), .dir(bird_dir[2]));
    direction_decode cld_pig   (.pre_dir(pre_pig_dir),     .dir(pig_dir));

    /// Force, Sequential
    always @(posedge clk) begin
        if(rst) begin
            bird_force_x[0] <= 0;                 
            bird_force_x[1] <= 0;
            bird_force_x[2] <= 0;
            bird_force_y[0] <= 0;   
            bird_force_y[1] <= 0;
            bird_force_y[2] <= 0;
            pig_force_x <= 0;
            pig_force_y <= 0;
        end
        else if(vsync) begin
            bird_force_x[0] <= next_bird_force_x[0];
            bird_force_x[1] <= next_bird_force_x[1];
            bird_force_x[2] <= next_bird_force_x[2];
            bird_force_y[0] <= next_bird_force_y[0];
            bird_force_y[1] <= next_bird_force_y[1];
            bird_force_y[2] <= next_bird_force_y[2];
            pig_force_x <= next_pig_force_x;
            pig_force_y <= next_pig_force_y;
        end
        else begin
            bird_force_x[0] <= bird_force_x[0];
            bird_force_x[1] <= bird_force_x[1];
            bird_force_x[2] <= bird_force_x[2];
            bird_force_y[0] <= bird_force_y[0];
            bird_force_y[1] <= bird_force_y[1];
            bird_force_y[2] <= bird_force_y[2];
            pig_force_x <= pig_force_x;
            pig_force_y <= pig_force_y;
        end
    end

    parameter STICK_REPEL = 17'd40;
    /// Force, Phase 1
    always @* begin  
        next_bird_force_x[0] = 0;                 
        next_bird_force_x[1] = 0;
        next_bird_force_x[2] = 0;
        next_bird_force_y[0] = 0;   
        next_bird_force_y[1] = 0;
        next_bird_force_y[2] = 0;
        next_pig_force_x = 0;
        next_pig_force_y = 0;
        case (collide)              // Who are colliding
        4'b0011 : begin
            if(ooii) begin
                next_bird_force_x[0] = STICK_REPEL;
                next_bird_force_y[0] = -STICK_REPEL;
                next_pig_force_x = -STICK_REPEL;
                next_pig_force_y = -STICK_REPEL;
            end else begin
            case (bird_dir[0])  // Which direction of collider A
            3'd0    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 2);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = bird_vx[0] >>> 1;
                    next_pig_force_y = bird_vy[0];
            end
            3'd1    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = bird_vx[0];
                    next_pig_force_y = bird_vy[0];    
            end
            3'd2    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy;
                    next_pig_force_x = bird_vx[0];
                    next_pig_force_y = bird_vy[0] >>> 1;    
            end
            3'd3    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = bird_vx[0] >>> 1;
                    next_pig_force_y = bird_vy[0] >>> 1;    
                
            end
            3'd4    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = bird_vx[0] >>> 1;
                    next_pig_force_y = bird_vy[0] >>> 1;    
            end
            3'd5    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = -(bird_vx[0] >>> 1);
                    next_pig_force_y = bird_vy[0] >>> 1;    
            end
            3'd6    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = bird_vx[0] >>> 1;
                    next_pig_force_y = bird_vy[0];    
            end
            3'd7    : begin
                    next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                    next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                    next_pig_force_x = bird_vx[0];
                    next_pig_force_y = bird_vy[0];    
            end
            default : begin
                next_bird_force_x[0] = pig_vx - (bird_vx[0] >>> 1);
                next_bird_force_y[0] = pig_vy - (bird_vy[0] >>> 1);
                next_pig_force_x = bird_vx[0] >>> 1;
                next_pig_force_y = bird_vy[0] >>> 1;
            end
            endcase
            end
        end
        4'b0101 : begin
            if(oioi) begin
                next_bird_force_x[1] = STICK_REPEL;
                next_bird_force_y[1] = -STICK_REPEL;
                next_pig_force_x = -STICK_REPEL;
                next_pig_force_y = -STICK_REPEL;
            end else begin
            case (bird_dir[1])  
            3'd0    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 2);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1] >>> 1;
                next_pig_force_y = bird_vy[1];
            end
            3'd1    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1];
                next_pig_force_y = bird_vy[1];
            end
            3'd2    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy;
                next_pig_force_x = bird_vx[1];
                next_pig_force_y = bird_vy[1] >>> 1;
            end
            3'd3    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1] >>> 1;
                next_pig_force_y = bird_vy[1] >>> 1;
            end
            3'd4    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1] >>> 1;
                next_pig_force_y = bird_vy[1] >>> 1;
            end
            3'd5    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = -(bird_vx[1] >>> 1);
                next_pig_force_y = bird_vy[1] >>> 1;
            end
            3'd6    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1] >>> 1;
                next_pig_force_y = bird_vy[1];
            end
            3'd7    : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1];
                next_pig_force_y = bird_vy[1];
            end
            default : begin
                next_bird_force_x[1] = pig_vx - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = pig_vy - (bird_vy[1] >>> 1);
                next_pig_force_x = bird_vx[1] >>> 1;
                next_pig_force_y = bird_vy[1] >>> 1;
            end
            endcase
            end
        end
        4'b1001 : begin
            if(iooi) begin
                next_bird_force_x[2] = STICK_REPEL;
                next_bird_force_y[2] = -STICK_REPEL;
                next_pig_force_x = -STICK_REPEL;
                next_pig_force_y = -STICK_REPEL;
            end else begin
            case (bird_dir[2])  
            3'd0    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 2);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2] >>> 1;
                next_pig_force_y = bird_vy[2];
            end
            3'd1    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2];
                next_pig_force_y = bird_vy[2];
            end
            3'd2    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy;
                next_pig_force_x = bird_vx[2];
                next_pig_force_y = bird_vy[2] >>> 1;
            end
            3'd3    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2] >>> 1;
                next_pig_force_y = bird_vy[2] >>> 1;
            end
            3'd4    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2] >>> 1;
                next_pig_force_y = bird_vy[2] >>> 1;
            end
            3'd5    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = -(bird_vx[2] >>> 1);
                next_pig_force_y = bird_vy[2] >>> 1;
            end
            3'd6    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2] >>> 1;
                next_pig_force_y = bird_vy[2];
            end
            3'd7    : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2];
                next_pig_force_y = bird_vy[2];
            end
            default : begin
                next_bird_force_x[2] = pig_vx - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = pig_vy - (bird_vy[2] >>> 1);
                next_pig_force_x = bird_vx[2] >>> 1;
                next_pig_force_y = bird_vy[2] >>> 1;
            end
            endcase
            end
        end
        4'b0110 : begin
            if(oiio) begin
                next_bird_force_x[0] = STICK_REPEL;
                next_bird_force_y[0] = -STICK_REPEL;
                next_bird_force_x[1] = -STICK_REPEL;
                next_bird_force_y[1] = -STICK_REPEL;
            end else begin
            case (bird_dir[1])  
            3'd0    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 2);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1] >>> 1;
                next_bird_force_y[0] = bird_vy[1];
            end
            3'd1    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1];
                next_bird_force_y[0] = bird_vy[1];
            end
            3'd2    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0];
                next_bird_force_x[0] = bird_vx[1];
                next_bird_force_y[0] = bird_vy[1] >>> 1;
            end
            3'd3    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1] >>> 1;
                next_bird_force_y[0] = bird_vy[1] >>> 1;
            end
            3'd4    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1] >>> 1;
                next_bird_force_y[0] = bird_vy[1] >>> 1;
            end
            3'd5    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = -(bird_vx[1] >>> 1);
                next_bird_force_y[0] = bird_vy[1] >>> 1;
            end
            3'd6    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1] >>> 1;
                next_bird_force_y[0] = bird_vy[1];
            end
            3'd7    : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1];
                next_bird_force_y[0] = bird_vy[1];
            end
            default : begin
                next_bird_force_x[1] = bird_vx[0] - (bird_vx[1] >>> 1);
                next_bird_force_y[1] = bird_vy[0] - (bird_vy[1] >>> 1);
                next_bird_force_x[0] = bird_vx[1] >>> 1;
                next_bird_force_y[0] = bird_vy[1] >>> 1;
            end
            endcase
            end
        end
        4'b1010 : begin
            if(ioio) begin
                next_bird_force_x[0] = STICK_REPEL;
                next_bird_force_y[0] = -STICK_REPEL;
                next_bird_force_x[2] = -STICK_REPEL;
                next_bird_force_y[2] = -STICK_REPEL;
            end else begin
            case (bird_dir[2])  
            3'd0    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 2);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2] >>> 1;
                next_bird_force_y[0] = bird_vy[2];
            end
            3'd1    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2];
                next_bird_force_y[0] = bird_vy[2];
            end
            3'd2    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0];
                next_bird_force_x[0] = bird_vx[2];
                next_bird_force_y[0] = bird_vy[2] >>> 1;
            end
            3'd3    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2] >>> 1;
                next_bird_force_y[0] = bird_vy[2] >>> 1;
            end
            3'd4    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2] >>> 1;
                next_bird_force_y[0] = bird_vy[2] >>> 1;
            end
            3'd5    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = -(bird_vx[2] >>> 1);
                next_bird_force_y[0] = bird_vy[2] >>> 1;
            end
            3'd6    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2] >>> 1;
                next_bird_force_y[0] = bird_vy[2];
            end
            3'd7    : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2];
                next_bird_force_y[0] = bird_vy[2];
            end
            default : begin
                next_bird_force_x[2] = bird_vx[0] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[0] - (bird_vy[2] >>> 1);
                next_bird_force_x[0] = bird_vx[2] >>> 1;
                next_bird_force_y[0] = bird_vy[2] >>> 1;
            end
            endcase
            end
        end
        4'b1100 : begin
            if(iioo) begin
                next_bird_force_x[1] = STICK_REPEL;
                next_bird_force_y[1] = -STICK_REPEL;
                next_bird_force_x[2] = -STICK_REPEL;
                next_bird_force_y[2] = -STICK_REPEL;
            end else begin
            case (bird_dir[2])  
            3'd0    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 2);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2] >>> 1;
                next_bird_force_y[1] = bird_vy[2];
            end
            3'd1    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2];
                next_bird_force_y[1] = bird_vy[2];
            end
            3'd2    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1];
                next_bird_force_x[1] = bird_vx[2];
                next_bird_force_y[1] = bird_vy[2] >>> 1;
            end
            3'd3    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2] >>> 1;
                next_bird_force_y[1] = bird_vy[2] >>> 1;
            end
            3'd4    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2] >>> 1;
                next_bird_force_y[1] = bird_vy[2] >>> 1;
            end
            3'd5    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = -(bird_vx[2] >>> 1);
                next_bird_force_y[1] = bird_vy[2] >>> 1;
            end
            3'd6    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2] >>> 1;
                next_bird_force_y[1] = bird_vy[2];
            end
            3'd7    : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2];
                next_bird_force_y[1] = bird_vy[2];
            end
            default : begin
                next_bird_force_x[2] = bird_vx[1] - (bird_vx[2] >>> 1);
                next_bird_force_y[2] = bird_vy[1] - (bird_vy[2] >>> 1);
                next_bird_force_x[1] = bird_vx[2] >>> 1;
                next_bird_force_y[1] = bird_vy[2] >>> 1;
            end
            endcase
            end
        end
        4'b0111 : begin
            next_bird_force_x[0] = STICK_REPEL;
            next_bird_force_y[0] = -STICK_REPEL;
            next_bird_force_x[1] = -STICK_REPEL;
            next_bird_force_y[1] = -STICK_REPEL;
            next_pig_force_x = 0;
            next_pig_force_y = -STICK_REPEL;
        end
        4'b1011 : begin
            next_bird_force_x[0] = STICK_REPEL;
            next_bird_force_y[0] = -STICK_REPEL;
            next_bird_force_x[2] = -STICK_REPEL;
            next_bird_force_y[2] = -STICK_REPEL;
            next_pig_force_x = 0;
            next_pig_force_y = -STICK_REPEL;
        end
        4'b1101 : begin
            next_bird_force_x[1] = STICK_REPEL;
            next_bird_force_y[1] = -STICK_REPEL;
            next_bird_force_x[2] = -STICK_REPEL;
            next_bird_force_y[2] = -STICK_REPEL;
            next_pig_force_x = 0;
            next_pig_force_y = -STICK_REPEL;
        end
        4'b1110 : begin
            next_bird_force_x[1] = STICK_REPEL;
            next_bird_force_y[1] = -STICK_REPEL;
            next_bird_force_x[2] = -STICK_REPEL;
            next_bird_force_y[2] = -STICK_REPEL;
            next_bird_force_x[0] = STICK_REPEL;
            next_bird_force_y[0] = -STICK_REPEL;
        end
        4'b1111 : begin
            next_bird_force_x[1] = STICK_REPEL;
            next_bird_force_y[1] = -STICK_REPEL;
            next_bird_force_x[2] = -STICK_REPEL;
            next_bird_force_y[2] = -STICK_REPEL;
            next_pig_force_x = 0;
            next_pig_force_y = -STICK_REPEL;
            next_bird_force_x[0] = STICK_REPEL;
            next_bird_force_y[0] = -STICK_REPEL;
        end
        default : begin
            next_bird_force_x[0] = 0;                 
            next_bird_force_x[1] = 0;
            next_bird_force_x[2] = 0;
            next_bird_force_y[0] = 0;   
            next_bird_force_y[1] = 0;
            next_bird_force_y[2] = 0;
            next_pig_force_x = 0;
            next_pig_force_y = 0;
        end
        endcase
    end

endmodule

module direction_decode(
    input [4-1:0] pre_dir,
    output reg [3-1:0] dir
);

    always @* begin
        case (pre_dir)
        4'b1000, 4'b1010    : dir = 3'd0;
        4'b1001, 4'b1011    : dir = 3'd4;
        4'b0110, 4'b0111    : dir = 3'd2;
        4'b0100, 4'b0101    : dir = 3'd6;
        4'b0010             : dir = 3'd1;
        4'b0011             : dir = 3'd3;
        4'b0001             : dir = 3'd5;
        4'b0000             : dir = 3'd7;
        default : dir = 3'd0;
        endcase
    end 
endmodule