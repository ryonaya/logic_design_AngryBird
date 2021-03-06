
module top(
    input clk,
    input pre_rst,          // button U for now.
    inout PS2_CLK,
    inout PS2_DATA,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue, 
    output hsync,
    output vsync
);

    parameter MENU = 2'd0,
              GAME = 2'd1,
              SCOR = 2'd2;
    parameter NONE   = 3'd7,
              BIRD_0 = 3'd0,                
              BIRD_1 = 3'd1,                // All the bird before BIRD_N should hold their pos,
              BIRD_2 = 3'd2;                //      but need to react to Collision.
    parameter WAIT_FOR_LOAD = 2'd0,         // ALL Active Bird should hold their position (initial -> ( 0+(32*n) , y1 = 380) ).
              LOADING_ANIM  = 2'd1,         // Main Bird on interpolation of (64, 380) -> (100, 325). Others move to (x + 32, 380).
              WAIT_FOR_SHOT = 2'd2,         // Main Bird should on (100, 325), 
              FLYING        = 2'd3;         // Main Bird should fly to random place, and then change state to WAIT_FOR_LOAD.

    /// <DECLARATION_Basics>
    ///
    /// </DECLARATION_Basics>
    wire [12-1:0] data_12b;
    wire [5-1:0]  data_5b;
    wire clk_25MHz;
    wire db_rst, rst;
    wire [10-1:0] h_cnt,   //640
                  v_cnt;   //480
    wire valid;
    genvar i;

    /// <DECLARATION_Pipeline>
    /// 1 : Collision
    /// 2 : Bird, Pig Velocity1
    /// 3 : Bird, Pig Velocity2
    /// 4 : Bird, Pig Position
    /// 5 : Bird, Pig Position
    /// 6 : State Change
    /// </DECLARATION_Pipeline>
    wire op_vsync1, inv_vsync;
    reg  op_vsync2, op_vsync3, op_vsync4, op_vsync5, op_vsync6;

    /// <DECLARATION_Inputs>
    ///
    /// </DECLARATION_Inputs>
    wire SPACE_down, pre_SPACE_down, W_down, A_down, S_down, D_down;


    /// <DECLARATION_Pixels>
    ///
    /// </DECLARATION_Pixels>
    wire [17-1:0] bg_pixel_addr;            // background   : 76800
    wire [10-1:0] bird_pixel_addr [3-1:0];  // bird         : 1024
    reg  [10-1:0] valid_bird_pixel_addr;
    wire [10-1:0] pig_pixel_addr;           // pig          : 1024
    wire [12-1:0] slingshot_pixel_addr;     // slingshot    : 2610
    wire [5-1:0]  pre_bg_pixel;             // 12 bits -> 5 bits
    wire [12-1:0] bg_pixel, 
                  pig_pixel, 
                  slingshot_pixel,
                  bird_pixel;
    reg  [12-1:0] bird_pig_pixel, 
                  pixel;
    reg  [12-1:0] color;
    wire [3-1:0]  bird;
    wire any_bird, 
         pig, 
         slingshot;

    /// <DECLARATION_Collides>
    ///
    /// </DECLARATION_Collides>
    wire [17-1:0] bird_force_x [3-1:0];
    wire [17-1:0] bird_force_y [3-1:0];
    wire [17-1:0] pig_force_x;
    wire [17-1:0] pig_force_y;
    wire [4-1:0] collide;
    reg  [4-1:0] op_collide;
    assign collide = {bird, pig};
    // always @(posedge clk) begin
    //     if(|collide)
    //         op_collide <= collide;
    //     else if(op_vsync6)
    //         op_collide <= 0;
    //     else 
    //         op_collide <= op_collide;
    // end
    // collide_onepulse opcollide (.s_op(op_collide), .s(collide), .clk(clk), .clk_25MHz(clk_25MHz), .vsync(op_vsync6));
    // onepulse opcollide [4-1:0] (.s_op(op_collide), .s(collide), .clk(clk_25MHz));

    /// <DECLARATION_Pig>
    /// 
    /// </DECLARATION_Pig>
    wire [17-1:0] pig_vx;
    wire [17-1:0] pig_vy;
    wire [4-1:0]  pig_dir;


    /// <DECLARATION_Birds>
    ///     Including Bird animation, force, deltaXY
    /// </DECLARATION_Birds>
    wire[17-1:0] bird_vx [3-1:0];
    wire[17-1:0] bird_vy [3-1:0];
    reg [2-1:0]  game_state, next_game_state;
    reg [3-1:0]  bird_macro_state, next_bird_macro_state;
    reg [2-1:0]  bird_state, next_bird_state;
    reg signed [17-1:0] deltaX, deltaY, next_deltaX, next_deltaY;
    reg [10-1:0] cnt;                       // 0~1023, used to trigger state change and control animation position
    wire [4-1:0] bird_dir [3-1:0];          // Four direction, used in collision detection  

    always @(posedge clk) begin             // Bird behaviour counter
        if(rst) begin
            cnt <= 0;
        end
        else if(op_vsync1) begin
            if(bird_state == LOADING_ANIM || bird_state == FLYING) 
                cnt <= cnt + 1;
            else
                cnt <= 0;
        end
        else begin
            cnt <= cnt;
        end
    end


    ///   <Game State>
    /// Game flow control
    ///   </Game State>
   `define DEFAULT_GAME_STATE GAME          // Focus on GAME scene for now.
    always @(posedge clk) begin             // Game state control
        if(rst) game_state <= `DEFAULT_GAME_STATE;
        else    game_state <= next_game_state;
    end
    always @* begin
        case (game_state)
            MENU    : next_game_state = game_state;
            GAME    : next_game_state = game_state;
            SCOR    : next_game_state = game_state;
            default : next_game_state = `DEFAULT_GAME_STATE; 
        endcase
    end


    ///   <Bird Macro State>
    /// Determine which is the Main Bird.
    ///   </Bird Macro State>
    always @(posedge clk) begin             // Bird macro state control
        if(rst)             bird_macro_state <= BIRD_0;
        else if(op_vsync1)  bird_macro_state <= next_bird_macro_state;
        else                bird_macro_state <= bird_macro_state;
    end
    always @* begin
        case (bird_macro_state)
            NONE    : next_bird_macro_state = NONE;     ////////////////////////////////
            BIRD_0  : next_bird_macro_state = (cnt > 10'd480) ? BIRD_1 : BIRD_0;
            BIRD_1  : next_bird_macro_state = (cnt > 10'd480) ? BIRD_2 : BIRD_1;
            BIRD_2  : next_bird_macro_state = (cnt > 10'd480) ? NONE   : BIRD_2;
            default : next_bird_macro_state = BIRD_0 ; 
        endcase
    end


    ///   <Bird State>
    /// 
    ///   </Bird State>
    always @(posedge clk) begin             // Bird state control
        if(rst)             bird_state <= WAIT_FOR_LOAD;
        else if(op_vsync1)  bird_state <= next_bird_state;
        else                bird_state <= bird_state;
    end
    always @* begin
        case (bird_state)
            WAIT_FOR_LOAD   : next_bird_state = LOADING_ANIM;
            LOADING_ANIM    : next_bird_state = (cnt >= 10'd31)   ? WAIT_FOR_SHOT : LOADING_ANIM;
            WAIT_FOR_SHOT   : next_bird_state = (SPACE_down == 1) ? FLYING        : WAIT_FOR_SHOT;
            FLYING          : next_bird_state = (cnt >= 10'd480)  ? WAIT_FOR_LOAD : FLYING;     // Wait for 8 seconds
            default         : next_bird_state = WAIT_FOR_LOAD; 
        endcase
    end


    ///   <Color>   
    /// RGB output logic
    ///   </Color>  
    always @* begin
        if(valid) begin
            if((any_bird == 1 || pig == 1) && bird_pig_pixel != 12'hF6F)    color = bird_pig_pixel;
            else if(slingshot && slingshot_pixel != 12'hF6F)                color = slingshot_pixel;
            else                                                            color = bg_pixel;
        end
        else color = 12'h0;
    end 
    always @* begin         // Birds and Pigs are on the same layer
        if(any_bird)
            bird_pig_pixel = bird_pixel;
        else 
            bird_pig_pixel = pig_pixel;
    end
    assign any_bird = |bird;
    assign {vgaRed, vgaGreen, vgaBlue} = {color[11:8], color[7:4], color[3:0]};


    ///   <Utilities>   
    /// Clock Divisor and VGA Controller
    ///   </Utilities> 
    clock_divisor                               clk_wiz_0_inst(
        .clk(clk),
        .clk1(clk_25MHz)
    );
    vga_controller                              vga_inst(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );


    ///   <Background>   
    /// Generates Background pixels
    ///   </Background> 
    assign bg_pixel_addr = (h_cnt>>1) + 320 * (v_cnt>>1);   // display 320*240 image in 640*480 screen
    blk_mem_gen_0                               bg_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(bg_pixel_addr),
        .dina(data_5b),
        .douta(pre_bg_pixel)
    ); 
    bg_pixel_decode                             bg_decode(
        .pre_bg_pixel(pre_bg_pixel),
        .bg_pixel(bg_pixel)
    );


    ///   <Bird>
    /// Generates Bird pixels
    ///   </Bird>
    always @* begin     // Combine bird pixel
        case (bird)
            3'b001  : valid_bird_pixel_addr = bird_pixel_addr[0];
            3'b010  : valid_bird_pixel_addr = bird_pixel_addr[1];
            3'b100  : valid_bird_pixel_addr = bird_pixel_addr[2];
            3'b011  : valid_bird_pixel_addr = bird_pixel_addr[0];
            3'b101  : valid_bird_pixel_addr = bird_pixel_addr[0];
            3'b111  : valid_bird_pixel_addr = bird_pixel_addr[0];
            3'b110  : valid_bird_pixel_addr = bird_pixel_addr[1];
            default : valid_bird_pixel_addr = 10'b0;
        endcase
    end
    blk_mem_gen_1                               bird_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(valid_bird_pixel_addr),
        .dina(data_12b),
        .douta(bird_pixel)
    );
generate
    for(i = 0; i < 3; i = i+1) begin
        bird #(.IX(80-32*i), .IY(395), .NUM(i)) bird_mem_addr_gen (
            .clk(clk),
            .rst(rst),
            .vsync (op_vsync1),
            .vsync2(op_vsync2),
            .vsync3(op_vsync1),
            .vsync4(op_vsync2),
            .h_cnt(h_cnt),
            .v_cnt(v_cnt),                          // basic i

            .macro_state(bird_macro_state),
            .state(bird_state),
            .cnt(cnt),
            .pulse_en(SPACE_down),
            .deltaX(deltaX),
            .deltaY(deltaY),                        // main i
            .bird_force_x(bird_force_x[i]),
            .bird_force_y(bird_force_y[i]),

            .vx(bird_vx[i]),
            .vy(bird_vy[i]),
            .bird(bird[i]),
            .bird_pixel_addr(bird_pixel_addr[i]),
            .bird_dir(bird_dir[i])                  // o
        );
    end
endgenerate


    ///   <SlingShot>   (x1 = 101, y1 = 325)
    /// Generates SlingShot pixels
    ///   </SlingShot>
    blk_mem_gen_2                               slingshot_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(slingshot_pixel_addr),
        .dina(data_12b),
        .douta(slingshot_pixel)
    );
    slingshot                                   slingshot_mem_addr_gen(
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),                              // i
        .slingshot(slingshot),
        .slingshot_pixel_addr(slingshot_pixel_addr) // o
    );


    ///   <Pig>
    /// Generates Pig pixels
    ///   </Pig>
    blk_mem_gen_3                               pig_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pig_pixel_addr),
        .dina(data_12b),
        .douta(pig_pixel)
    );
    pig #(.IX(500), .IY(395))                   pig_mem_addr_gen(
        .clk(clk),
        .vsync (op_vsync1),  
        .vsync2(op_vsync1),
        .vsync3(op_vsync1),
        .rst(rst),             
        .h_cnt(h_cnt),      
        .v_cnt(v_cnt),                  // basic i
        .pig_force_x(pig_force_x),
        .pig_force_y(pig_force_y),      // main i

        .vx(pig_vx),
        .vy(pig_vy),
        .pig(pig),      
        .pig_pixel_addr(pig_pixel_addr), // o
        .pig_dir(pig_dir)
    );


    ///   <Collision>
    /// Thickiest sub module
    ///   </Collision>
    collision                                   collision_master(
        .clk(clk),
        .rst(rst),
        .vsync(op_vsync1),              // basic i

        .collide(collide),
        .big_pre_bird_dir ({bird_dir[2], bird_dir[1], bird_dir[0]}),
        .pre_pig_dir  (pig_dir),
        .big_bird_vx ({bird_vx[2], bird_vx[1], bird_vx[0]}),
        .big_bird_vy ({bird_vy[2], bird_vy[1], bird_vy[0]}),
        .pig_vx  (pig_vx),
        .pig_vy  (pig_vy),              // main i

        .big_bird_force_x ({bird_force_x[2], bird_force_x[1], bird_force_x[0]}),
        .big_bird_force_y ({bird_force_y[2], bird_force_y[1], bird_force_y[0]}),
        .pig_force_x  (pig_force_x),
        .pig_force_y  (pig_force_y)     // o
    );


    ///   <Keyboard>
    /// Keyboard input
    ///   </Keyboard>
	parameter [9-1:0] SPACE_CODE = 9'b0_0010_1001,	// SPACE -> 29
                      W_CODE     = 9'b0_0001_1101,	// W     -> 1D
                      A_CODE     = 9'b0_0001_1100,	// A     -> 1C
                      S_CODE     = 9'b0_0001_1011,	// S     -> 1B
                      D_CODE     = 9'b0_0010_0011;	// D     -> 23
	wire shift_down;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
    wire [4-1:0] keys;
	assign pre_SPACE_down = (key_down[SPACE_CODE] == 1'b1) ? 1'b1 : 1'b0;
    assign W_down         = (key_down[W_CODE] == 1'b1)     ? 1'b1 : 1'b0;
    assign A_down         = (key_down[A_CODE] == 1'b1)     ? 1'b1 : 1'b0;
    assign S_down         = (key_down[S_CODE] == 1'b1)     ? 1'b1 : 1'b0;
    assign D_down         = (key_down[D_CODE] == 1'b1)     ? 1'b1 : 1'b0;
    assign keys           = {W_down, A_down, S_down, D_down};
	KeyboardDecoder                         key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);


    ///   <Slingshot Force Control>
    /// Control the deltaXY of Main Bird 
    ///   </Slingshot Force Control>
    // wire [15-1:0] tmp_deltaX, tmp_deltaY;
    // assign tmp_deltaX = next_deltaX * next_deltaX;
    // assign tmp_deltaY = next_deltaY * next_deltaY;
    always @(posedge clk) begin     // Sequential and boundary control
        if(rst) begin
            deltaX <= 0;
            deltaY <= 0;
        end
        else if(op_vsync1) begin
            if( ((next_deltaX[15] == 0 && next_deltaX > 16'd63) || (next_deltaX[15] == 1 && next_deltaX < -16'd63)) || 
                ((next_deltaY[15] == 0 && next_deltaY > 16'd63) || (next_deltaY[15] == 1 && next_deltaY < -16'd63)) ) begin
            // if( tmp_deltaX + tmp_deltaY > 15'd2304) begin       // radius = 48       // Consume 1.5~2.0 ns
                deltaX <= deltaX;
                deltaY <= deltaY;
            end
            else begin
                deltaX <= next_deltaX;
                deltaY <= next_deltaY;
            end
        end
        else begin
            deltaX <= deltaX;
            deltaY <= deltaY;
        end
    end
    always @* begin                 // Conbinational
        if(bird_state == WAIT_FOR_SHOT) begin
            case({keys[3], keys[1]}) 
                2'b10   : next_deltaY = deltaY - 16'd1;
                2'b01   : next_deltaY = deltaY + 16'd1;
                default : next_deltaY = deltaY;
            endcase
            case({keys[2], keys[0]}) 
                2'b10   : next_deltaX = deltaX - 16'd1;
                2'b01   : next_deltaX = deltaX + 16'd1;
                default : next_deltaX = deltaX;
            endcase
        end
        else begin
            next_deltaX = 0;
            next_deltaY = 0;
        end
    end

    
    ///   <Others>
    /// One pulse , Debounce and Pipeline
    ///   </Others>
    debounce dbrst(.s_db(db_rst),       .s(pre_rst),    .clk(clk));
    onepulse oprst(.s_op(rst),          .s(db_rst),     .clk(clk));
    assign inv_vsync = !vsync;
    onepulse opvsync(.s_op(op_vsync1),   .s(inv_vsync),  .clk(clk));
    onepulse opspace (.s(pre_SPACE_down), .s_op(SPACE_down), .clk(op_vsync1));
    assign data_5b = data_12b[4:0];

    always @(posedge clk) begin
        op_vsync2 <= op_vsync1;
        op_vsync3 <= op_vsync2;
        op_vsync4 <= op_vsync3;
        op_vsync5 <= op_vsync4;
        op_vsync6 <= op_vsync5;
    end

endmodule
