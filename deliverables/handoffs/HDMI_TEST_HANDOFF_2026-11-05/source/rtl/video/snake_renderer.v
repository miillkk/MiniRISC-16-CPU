`timescale 1ns/1ps

module snake_renderer (
    input  wire [9:0]   pixel_x,
    input  wire [9:0]   pixel_y,
    input  wire         active_video,
    input  wire [575:0] frame_data,
    input  wire [5:0]   head_position,
    input  wire         frame_valid,
    input  wire         load_mode,
    input  wire         test_pattern,
    output reg  [7:0]   y_value,
    output reg  [7:0]   cb_value,
    output reg  [7:0]   cr_value
);
    localparam BOARD_X = 128;
    localparam BOARD_Y = 80;
    reg [7:0] status_char;
    reg [7:0] overlay_char;
    reg [2:0] font_row, font_col;
    reg [2:0] overlay_row, overlay_col;
    wire status_pixel;
    wire overlay_pixel;
    reg [5:0] cell_index;
    reg [7:0] cell_value;
    reg [7:0] food_position;
    reg [7:0] score_value, high_value, level_value, switch_value, status_value;
    integer local_x, local_y, cell_x, cell_y, char_index, overlay_index;
    integer score_h, score_t, score_o, high_h, high_t, high_o;
    reg status_region, overlay_region;
    reg [3:0] color_code;

    font5x7 u_status_font(.character(status_char),.row(font_row),.column(font_col),.pixel_on(status_pixel));
    font5x7 u_overlay_font(.character(overlay_char),.row(overlay_row),.column(overlay_col),.pixel_on(overlay_pixel));

    function [7:0] frame_byte;
        input integer byte_index;
        begin frame_byte = frame_data[byte_index*8 +: 8]; end
    endfunction

    task select_palette;
        input [3:0] code;
        begin
            case (code)
                4'd0: begin y_value=8'd16;  cb_value=8'd128; cr_value=8'd128; end
                4'd1: begin y_value=8'd27;  cb_value=8'd132; cr_value=8'd126; end
                4'd2: begin y_value=8'd42;  cb_value=8'd134; cr_value=8'd121; end
                4'd3: begin y_value=8'd62;  cb_value=8'd133; cr_value=8'd120; end
                4'd4: begin y_value=8'd134; cb_value=8'd95;  cr_value=8'd67;  end
                4'd5: begin y_value=8'd184; cb_value=8'd96;  cr_value=8'd69;  end
                4'd6: begin y_value=8'd82;  cb_value=8'd90;  cr_value=8'd240; end
                4'd7: begin y_value=8'd119; cb_value=8'd128; cr_value=8'd128; end
                4'd8: begin y_value=8'd235; cb_value=8'd128; cr_value=8'd128; end
                4'd9: begin y_value=8'd192; cb_value=8'd30;  cr_value=8'd164; end
                4'd10:begin y_value=8'd84;  cb_value=8'd201; cr_value=8'd90;  end
                4'd11:begin y_value=8'd145; cb_value=8'd54;  cr_value=8'd34;  end
                4'd12:begin y_value=8'd170; cb_value=8'd166; cr_value=8'd16;  end
                4'd13:begin y_value=8'd107; cb_value=8'd202; cr_value=8'd222; end
                default: begin y_value=8'd16;cb_value=8'd128;cr_value=8'd128;end
            endcase
        end
    endtask

    always @* begin
        score_value = frame_byte(2);
        food_position = frame_byte(3);
        high_value = frame_byte(68);
        level_value = frame_byte(69);
        switch_value = frame_byte(70);
        status_value = frame_byte(1);
        score_h = score_value / 100;
        score_t = (score_value / 10) % 10;
        score_o = score_value % 10;
        high_h = high_value / 100;
        high_t = (high_value / 10) % 10;
        high_o = high_value % 10;
        status_char = " "; overlay_char = " ";
        font_row = 0; font_col = 0; overlay_row = 0; overlay_col = 0;
        status_region = 1'b0; overlay_region = 1'b0;
        cell_index = 0; cell_value = 0;
        local_x = 0; local_y = 0; cell_x = 0; cell_y = 0;
        char_index = 0; overlay_index = 0;
        color_code = 4'd1;

        if (pixel_y >= 10'd24 && pixel_y < 10'd38 && pixel_x >= 10'd136 && pixel_x < 10'd504) begin
            status_region = 1'b1;
            char_index = (pixel_x - 136) >> 4;
            font_col = ((pixel_x - 136) & 15) >> 1;
            font_row = (pixel_y - 24) >> 1;
            case (char_index)
                0:status_char="S";1:status_char="C";2:status_char="O";3:status_char="R";4:status_char="E";
                6:status_char=8'd48+score_h;7:status_char=8'd48+score_t;8:status_char=8'd48+score_o;
                10:status_char="H";11:status_char="I";12:status_char="G";13:status_char="H";
                15:status_char=8'd48+high_h;16:status_char=8'd48+high_t;17:status_char=8'd48+high_o;
                19:status_char="L";20:status_char="V";22:status_char=8'd48+(level_value & 3);
                default:status_char=" ";
            endcase
        end

        if (pixel_x >= BOARD_X && pixel_x < BOARD_X+384 && pixel_y >= BOARD_Y && pixel_y < BOARD_Y+384) begin
            local_x = pixel_x - BOARD_X;
            local_y = pixel_y - BOARD_Y;
            cell_index = (local_y/48)*8 + (local_x/48);
            cell_x = local_x % 48;
            cell_y = local_y % 48;
            cell_value = frame_byte(cell_index + 4);
            if (cell_x < 2 || cell_y < 2)
                color_code = 4'd3;
            else if (cell_value == 8'hFF)
                color_code = 4'd7;
            else if (cell_index == food_position[5:0])
                color_code = 4'd6;
            else if (cell_value != 0 && cell_index == head_position)
                color_code = 4'd5;
            else if (cell_value != 0)
                color_code = 4'd4;
            else
                color_code = 4'd2;
        end

        if (load_mode || status_value[7] || switch_value[2] || test_pattern || !frame_valid) begin
            if (pixel_y >= 10'd218 && pixel_y < 10'd246) begin
                if (load_mode) begin local_x=176; overlay_index=(pixel_x-176)>>5; end
                else if (status_value[7]) begin local_x=176; overlay_index=(pixel_x-176)>>5; end
                else if (switch_value[2]) begin local_x=240; overlay_index=(pixel_x-240)>>5; end
                else begin local_x=176; overlay_index=(pixel_x-176)>>5; end
                if (pixel_x >= local_x && pixel_x < local_x+288) begin
                    overlay_region = 1'b1;
                    overlay_col = ((pixel_x-local_x)&31)>>2;
                    overlay_row = (pixel_y-218)>>2;
                    if (load_mode) case(overlay_index) 0:overlay_char="L";1:overlay_char="O";2:overlay_char="A";3:overlay_char="D";5:overlay_char="M";6:overlay_char="O";7:overlay_char="D";8:overlay_char="E";default:overlay_char=" ";endcase
                    else if (status_value[7]) case(overlay_index) 0:overlay_char="G";1:overlay_char="A";2:overlay_char="M";3:overlay_char="E";5:overlay_char="O";6:overlay_char="V";7:overlay_char="E";8:overlay_char="R";default:overlay_char=" ";endcase
                    else if (switch_value[2]) case(overlay_index) 0:overlay_char="P";1:overlay_char="A";2:overlay_char="U";3:overlay_char="S";4:overlay_char="E";default:overlay_char=" ";endcase
                    else case(overlay_index) 0:overlay_char="H";1:overlay_char="D";2:overlay_char="M";3:overlay_char="I";5:overlay_char="T";6:overlay_char="E";7:overlay_char="S";8:overlay_char="T";default:overlay_char=" ";endcase
                end
            end
        end

        if (test_pattern || !frame_valid) begin
            if (pixel_x < 80) color_code=4'd8;
            else if (pixel_x < 160) color_code=4'd9;
            else if (pixel_x < 240) color_code=4'd4;
            else if (pixel_x < 320) color_code=4'd12;
            else if (pixel_x < 400) color_code=4'd6;
            else if (pixel_x < 480) color_code=4'd13;
            else if (pixel_x < 560) color_code=4'd10;
            else color_code=4'd1;
        end
        if (status_region && status_pixel)
            color_code = 4'd8;
        if (overlay_region && overlay_pixel)
            color_code = status_value[7] ? 4'd6 : (switch_value[2] ? 4'd9 : 4'd8);
        if (!active_video)
            color_code = 4'd0;
        select_palette(color_code);
    end
endmodule
