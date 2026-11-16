`timescale 1ns/1ps

// Four-phase board-level test for electrical coupling between HDMI I2C SCL
// and SDA.  No I2C transaction, CPU, video generator, or HDMI data is present.
module hdmi_i2c_cross_test_top #(
    parameter integer PHASE_CYCLES = 50_000_000
) (
    input  wire       clk_100mhz,
    input  wire       resetn,
    output wire [7:0] led,
    inout  wire       iic_scl_hdmi,
    inout  wire       iic_sda_hdmi
);
    wire rst;
    reg [25:0] phase_count;
    reg [1:0] phase;
    reg [1:0] scl_sync;
    reg [1:0] sda_sync;

    wire scl_drive_low = (phase == 2'b01);
    wire sda_drive_low = (phase == 2'b11);
    wire scl_release = ~scl_drive_low;
    wire sda_release = ~sda_drive_low;

    reset_conditioner u_reset_conditioner (
        .clk(clk_100mhz),
        .resetn(resetn),
        .rst(rst)
    );

    assign iic_scl_hdmi = scl_drive_low ? 1'b0 : 1'bz;
    assign iic_sda_hdmi = sda_drive_low ? 1'b0 : 1'bz;

    always @(posedge clk_100mhz) begin
        if (rst) begin
            phase_count <= 26'd0;
            phase <= 2'b00;
            scl_sync <= 2'b11;
            sda_sync <= 2'b11;
        end else begin
            scl_sync <= {scl_sync[0], iic_scl_hdmi};
            sda_sync <= {sda_sync[0], iic_sda_hdmi};
            if (phase_count == PHASE_CYCLES-1) begin
                phase_count <= 26'd0;
                phase <= phase + 1'b1;
            end else begin
                phase_count <= phase_count + 1'b1;
            end
        end
    end

    // LED7..6 identify the phase. LED3..0 show actual/command pairs:
    // {SDA pad, SDA release, SCL pad, SCL release}.
    assign led[7:6] = phase;
    assign led[5:4] = 2'b00;
    assign led[3] = sda_sync[1];
    assign led[2] = sda_release;
    assign led[1] = scl_sync[1];
    assign led[0] = scl_release;
endmodule

