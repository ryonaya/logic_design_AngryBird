
module top(
    input clk,
    input pre_rst,          // button U for now.
    inout PS2_CLK,
    inout PS2_DATA,
    output LED,
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
              BIRD_2 = 3'd2,                //      but need to react to Collision.
              LAST   = 3'd6;
    parameter WAIT_FOR_LOAD = 2'd0,         // ALL Active Bird should hold their position (initial -> ( 0+(32*n) , y1 = 380) ).
              LOADING_ANIM  = 2'd1,         // Main Bird on interpolation of (64, 380) -> (100, 325). Others move to (x + 32, 380).
              WAIT_FOR_SHOT = 2'd2,         // Main Bird should on (100, 325), 
              FLYING        = 2'd3;         // Main Bird should fly to random place, and then change state to WAIT_FOR_LOAD.
    parameter BROWN = 12'h840;

    /// <DECLARATION_Basics>
    ///
    /// </DECLARATION_Basics>
    wire [12-1:0] data_12b;
    wire [5-1:0]  data_5b;
    wire clk_25MHz;
    (* max_fanout = 16 *)wire db_rst, rst;
    wire op_vsync, inv_vsync;
    reg  op_vsync2, op_vsync3, op_vsync4, op_vsync5, op_vsync6;
    wire [10-1:0] h_cnt,   //640
                  v_cnt;   //480
    wire valid;
    wire SPACE_down, pre_SPACE_down, W_down, A_down, S_down, D_down;
    genvar i;
    
    
    /// <DECLARATION_Pixels>
    ///
    /// </DECLARATION_Pixels>
    wire [17-1:0] bg_pixel_addr;            // background   : 76800
    wire [5-1:0]  pre_bg_pixel;             // 12 bits -> 5 bits
    wire [17-1:0] menu_pixel_addr;          // menu         : 76800
    wire [5-1:0]  pre_menu_pixel;           // 12 bits -> 5 bits
    wire [17-1:0] scor_pixel_addr;          // scor         : 76800
    wire [5-1:0]  pre_scor_pixel;           // 12 bits -> 5 bits
    wire [10-1:0] bird_pixel_addr [3-1:0];  // bird         : 1024
    reg  [10-1:0] valid_bird_pixel_addr;
    wire [10-1:0] pig_pixel_addr;           // pig          : 1024
    wire [12-1:0] slingshot_pixel_addr;     // slingshot    : 2610
    wire [12-1:0] bg_pixel, 
                  menu_pixel, 
                  scor_pixel,
                  pig_pixel, 
                  slingshot_pixel,
                  bird_pixel;
    reg  [12-1:0] bird_pig_pixel, 
                  pixel;
    reg  [12-1:0] color;
    reg  on_line;                           // On slingshot rope
    wire signed [17-1:0] dx, dy;
    wire [3-1:0]  bird;
    wire any_bird, 
         pig, 
         slingshot;


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
    reg [10-1:0] cnt,                       // 0~1023, used to trigger state change and control animation position
                 menu_cnt;
    wire [4-1:0] bird_dir [3-1:0];          // Four direction, used in collision detection  

    always @(posedge clk) begin             // Bird behaviour counter
        if(rst) begin
            cnt <= 0;
        end 
        else if(op_vsync == 1) begin
            if( (bird_state == LOADING_ANIM || bird_state == FLYING) || (bird_macro_state == LAST)) 
                cnt <= cnt + 1;
            else
                cnt <= 0;
        end
        else begin
            cnt <= cnt;
        end
    end

    always @(posedge clk) begin             // Menu fade out counter
        if(rst) begin
            menu_cnt <= 0;
        end
        else if(op_vsync) begin
            if(game_state == MENU && SPACE_down && menu_cnt == 0)
                menu_cnt <= 1;
            else if(menu_cnt > 10'd128) 
                menu_cnt <= 0;
            else if(menu_cnt > 0)
                menu_cnt <= menu_cnt + 1;
            else 
                menu_cnt <= menu_cnt;
        end
        else begin
            menu_cnt <= menu_cnt;
        end
    end


    /// <DECLARATION_Collides>
    ///
    /// </DECLARATION_Collides>
    wire [17-1:0] bird_force_x [3-1:0];
    wire [17-1:0] bird_force_y [3-1:0];
    wire [17-1:0] pig_force_x;
    wire [17-1:0] pig_force_y;
    wire [4-1:0] collide;
    reg  [4-1:0] op_collide;
    assign collide = {(bird[2] && bird_macro_state > 1), (bird[1] && bird_macro_state > 0), bird[0], pig};           // Bird 2 1 0, pig 0
    always @(posedge clk) begin
        if(op_vsync2 || game_state != GAME || rst)
            op_collide <= 0;
        else if( (collide[0] + collide[1]) + (collide[2] + collide[3]) >= 2 )
            op_collide <= collide;
        else 
            op_collide <= op_collide;
    end


    ///   <Game State>
    /// Game flow control
    ///   </Game State>
   `define DEFAULT_GAME_STATE MENU
    always @(posedge clk) begin             // Game state control
        if(rst)             game_state <= `DEFAULT_GAME_STATE;
        else if(op_vsync)   game_state <= next_game_state;
        else                game_state <= game_state;
    end
    always @* begin
        case (game_state)
            MENU    : next_game_state = menu_cnt >= 10'd128                         ? GAME : MENU;
            GAME    : next_game_state = bird_macro_state == LAST && cnt >= 10'd120  ? SCOR : GAME;
            SCOR    : next_game_state = (SPACE_down)                                ? MENU : SCOR;      /////////////////////////////////
            default : next_game_state = `DEFAULT_GAME_STATE; 
        endcase
    end


    ///   <Bird Macro State>
    /// Determine which is the Main Bird.
    ///   </Bird Macro State>
    always @(posedge clk) begin             // Bird macro state control
        if(rst)             bird_macro_state <= NONE;
        else if(op_vsync)   bird_macro_state <= next_bird_macro_state;
        else                bird_macro_state <= bird_macro_state;
    end
    always @* begin
        case (bird_macro_state)
            NONE    : next_bird_macro_state = (game_state == GAME)  ? BIRD_0 : NONE;
            BIRD_0  : next_bird_macro_state = (cnt > 10'd480)       ? BIRD_1 : BIRD_0;
            BIRD_1  : next_bird_macro_state = (cnt > 10'd480)       ? BIRD_2 : BIRD_1;
            BIRD_2  : next_bird_macro_state = (cnt > 10'd480)       ? LAST   : BIRD_2;
            LAST    : next_bird_macro_state = (cnt > 10'd120)       ? NONE   : LAST;
            default : next_bird_macro_state = NONE; 
        endcase
    end


    ///   <Bird State>
    /// Determine Main Bird behaviour.
    ///   </Bird State>
    always @(posedge clk) begin             // Bird state control
        if(rst || game_state != GAME)   bird_state <= WAIT_FOR_LOAD;
        else if(op_vsync)               bird_state <= next_bird_state;
        else                            bird_state <= bird_state;
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
            case (game_state)
                MENU    : begin
                    color[3:0]  = menu_pixel[3:0] >>(menu_cnt>>5);
                    color[7:4]  = menu_pixel[7:4] >>(menu_cnt>>5);
                    color[11:8] = menu_pixel[11:8]>>(menu_cnt>>5);
                end
                GAME    :  begin
                    if(on_line)                                             color = BROWN;
                    else if((any_bird | pig) && bird_pig_pixel != 12'hF6F)  color = bird_pig_pixel;
                    else if(slingshot && slingshot_pixel != 12'hF6F)        color = slingshot_pixel;
                    else                                                    color = bg_pixel;
                end
                SCOR    :  begin
                    if(scor_pixel != 12'hf6f)                                   
                        color = scor_pixel;
                    else if((any_bird | pig) && bird_pig_pixel != 12'hF6F) begin
                        color[3:0]  = bird_pig_pixel[3:0] >> 1;
                        color[7:4]  = bird_pig_pixel[7:4] >> 1;
                        color[11:8] = bird_pig_pixel[11:8]>> 1;
                    end     
                    else if(slingshot && slingshot_pixel != 12'hF6F) begin
                        color[3:0]  = slingshot_pixel[3:0] >> 1;
                        color[7:4]  = slingshot_pixel[7:4] >> 1;
                        color[11:8] = slingshot_pixel[11:8]>> 1;
                    end           
                    else begin
                        color[3:0]  = bg_pixel[3:0] >> 1;
                        color[7:4]  = bg_pixel[7:4] >> 1;
                        color[11:8] = bg_pixel[11:8]>> 1;
                    end 
                end
                default : begin
                    color = 12'h0;
                end
            endcase
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

    /// Rope
    wire ul, ur, dl, dr;
    wire [3:0] sel;
    assign ul = (deltaX[16] == 1 && deltaY[16] == 1) && (h_cnt <= 10'd116 && h_cnt >= 10'd116+deltaX[9:0]) && (v_cnt <= 10'd341 && v_cnt >= 10'd341+deltaY[9:0]);
    assign ur = (deltaX[16] == 0 && deltaY[16] == 1) && (h_cnt >= 10'd116 && h_cnt <= 10'd116+deltaX[9:0]) && (v_cnt <= 10'd341 && v_cnt >= 10'd341+deltaY[9:0]);
    assign dl = (deltaX[16] == 1 && deltaY[16] == 0) && (h_cnt <= 10'd116 && h_cnt >= 10'd116+deltaX[9:0]) && (v_cnt >= 10'd341 && v_cnt <= 10'd341+deltaY[9:0]);
    assign dr = (deltaX[16] == 0 && deltaY[16] == 0) && (h_cnt >= 10'd116 && h_cnt <= 10'd116+deltaX[9:0]) && (v_cnt >= 10'd341 && v_cnt <= 10'd341+deltaY[9:0]);
    assign sel = {ul, ur, dl ,dr};
    assign dx = (h_cnt - 10'd116);
    assign dy = (v_cnt - 10'd341);
    always @(posedge clk_25MHz) begin
        if(game_state == GAME && deltaX != 0) begin
            if(|sel)
                on_line <= ( dy >= (dx * (deltaY)) / (deltaX) -1 ) && ( dy <= (dx * (deltaY)) / (deltaX) +1 );
            else 
                on_line <= 0;
        end
        else 
            on_line <= 0;
    end


    ///   <Utilities>   
    /// Clock Divisor and VGA Controller
    ///   </Utilities> 
    clock_divisor       clk_wiz_0_inst(
        .clk(clk),
        .clk1(clk_25MHz)
    );
    vga_controller      vga_inst(
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
    blk_mem_gen_0       bg_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(bg_pixel_addr),
        .dina(data_5b),
        .douta(pre_bg_pixel)
    ); 
    bg_pixel_decode     bg_decode(
        .pre_bg_pixel(pre_bg_pixel),
        .bg_pixel(bg_pixel)
    );


    ///   <Menu>   
    /// Generates Menu pixels
    ///   </Menu> 
    assign menu_pixel_addr = (h_cnt>>1) + 320 * (v_cnt>>1); // display 320*240 image in 640*480 screen
    blk_mem_gen_4       menu_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(menu_pixel_addr),
        .dina(data_5b),
        .douta(pre_menu_pixel)
    ); 
    menu_pixel_decode     menu_decode(
        .pre_menu_pixel(pre_menu_pixel),
        .menu_pixel(menu_pixel)
    );


    ///   <scor>   
    /// Generates scor pixels
    ///   </scor> 
    assign scor_pixel_addr = (h_cnt>>1) + 320 * (v_cnt>>1); // display 320*240 image in 640*480 screen
    blk_mem_gen_5       scor_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(scor_pixel_addr),
        .dina(data_5b),
        .douta(pre_scor_pixel)
    ); 
    scor_pixel_decode     scor_decode(
        .pre_scor_pixel(pre_scor_pixel),
        .scor_pixel(scor_pixel)
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
    blk_mem_gen_1       bird_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(valid_bird_pixel_addr),
        .dina(data_12b),
        .douta(bird_pixel)
    );
generate
    for(i = 0; i < 3; i = i+1) begin
        bird #(.IX(80-32*i), .IY(396), .NUM(i)) bird_mem_addr_gen (
            .clk(clk),
            .rst(rst),
            .vsync(op_vsync),
            .vsync2(op_vsync2),
            .h_cnt(h_cnt),
            .v_cnt(v_cnt),                          // basic i

            .macro_state(bird_macro_state),
            .state(bird_state),
            .game_state(game_state),
            .cnt(cnt),
            .pulse_en( (SPACE_down && game_state == GAME)),
            .deltaX(deltaX),
            .deltaY(deltaY),
            .bird_force_x(bird_force_x[i]),
            .bird_force_y(bird_force_y[i]),         // main i

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
    blk_mem_gen_2       slingshot_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(slingshot_pixel_addr),
        .dina(data_12b),
        .douta(slingshot_pixel)
    );
    slingshot           slingshot_mem_addr_gen(
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),                              // i
        .slingshot(slingshot),
        .slingshot_pixel_addr(slingshot_pixel_addr) // o
    );


    ///   <Pig>
    /// Generates Pig pixels
    ///   </Pig>
    blk_mem_gen_3       pig_inst(
        .clka(clk_25MHz),
        .wea(0),
        .addra(pig_pixel_addr),
        .dina(data_12b),
        .douta(pig_pixel)
    );
    pig #(.IX(500), .IY(396))                   pig_mem_addr_gen(
        .clk(clk),
        .vsync (op_vsync),
        .vsync2(op_vsync2),
        .rst(rst),             
        .h_cnt(h_cnt),      
        .v_cnt(v_cnt),                  // basic i

        .macro_state(bird_macro_state),
        .game_state(game_state),
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
        .vsync(op_vsync),              // basic i

        .collide(op_collide),
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
	KeyboardDecoder key_de (
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
    always @(posedge clk) begin     // Sequential and boundary control
        if(rst) begin
            deltaX <= 0;
            deltaY <= 0;
        end
        else if(op_vsync) begin
            if( ((next_deltaX[16] == 0 && next_deltaX > 17'd63) || (next_deltaX[16] == 1 && next_deltaX < -17'd63)) || 
                ((next_deltaY[16] == 0 && next_deltaY > 17'd63) || (next_deltaY[16] == 1 && next_deltaY < -17'd63)) ) begin
            // if( (next_deltaX * next_deltaX) + (next_deltaY * next_deltaY) < 2304)       // radius = 48
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
                2'b10   : next_deltaY = deltaY - 17'd1;
                2'b01   : next_deltaY = deltaY + 17'd1;
                default : next_deltaY = deltaY;
            endcase
            case({keys[2], keys[0]}) 
                2'b10   : next_deltaX = deltaX - 17'd1;
                2'b01   : next_deltaX = deltaX + 17'd1;
                default : next_deltaX = deltaX;
            endcase
        end
        else begin
            next_deltaX = 0;
            next_deltaY = 0;
        end
    end

    
    ///   <Others>
    /// One pulse and Debounce
    ///   </Others>
    debounce dbrst(.s_db(db_rst),       .s(pre_rst),    .clk(clk));
    onepulse oprst(.s_op(rst),          .s(db_rst),     .clk(clk));
    assign inv_vsync = !vsync;
    onepulse opvsync(.s_op(op_vsync),   .s(inv_vsync),  .clk(clk));
    onepulse opspace (.s(pre_SPACE_down), .s_op(SPACE_down), .clk(op_vsync));
    assign data_5b = data_12b[4:0];

    always @(posedge clk) begin
        op_vsync2 <= op_vsync;
        op_vsync3 <= op_vsync2;
        op_vsync4 <= op_vsync3;
        op_vsync5 <= op_vsync4;
        op_vsync6 <= op_vsync5;
    end 

endmodule
