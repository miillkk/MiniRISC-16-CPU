`timescale 1ns/1ps

// Board-level electrical diagnostic for the ADV7511 configuration bus.
// No CPU, video generator, HDMI controller, or I2C transaction is present.
module hdmi_i2c_electrical_test_top #(
    parameter integer HALF_PERIOD_CYCLES = 50_000_000
) (
    input  wire       clk_100mhz,
    input  wire       resetn,
    output wire [7:0] led,
    inout  wire       iic_scl_hdmi,
    inout  wire       iic_sda_hdmi
);
    wire rst;
    reg [25:0] half_period_count;
    reg scl_drive_low;
    reg [1:0] scl_sync;
    reg [1:0] sda_sync;

    reset_conditioner u_reset_conditioner (
        .clk(clk_100mhz),
        .resetn(resetn),
        .rst(rst)
    );

    // Open-drain test stimulus: drive SCL low for half a second, then release
    // it for half a second. SDA is always released, so no I2C START is issued.
    assign iic_scl_hdmi = scl_drive_low ? 1'b0 : 1'bz;
    assign iic_sda_hdmi = 1'bz;

    always @(posedge clk_100mhz) begin
        if (rst) begin
            half_period_count <= 26'd0;
            scl_drive_low <= 1'b0;
            scl_sync <= 2'b11;
            sda_sync <= 2'b11;
        end else begin
            scl_sync <= {scl_sync[0], iic_scl_hdmi};
            sda_sync <= {sda_sync[0], iic_sda_hdmi};
            if (half_period_count == HALF_PERIOD_CYCLES-1) begin
                half_period_count <= 26'd0;
                scl_drive_low <= ~scl_drive_low;
            end else begin
                half_period_count <= half_period_count + 1'b1;
            end
        end
    end

    // Expected release half-cycle: L2,L1,L0 on and L3 off.
    // Expected driven-low half-cycle: L3,L2 on and L1,L0 off.
    assign led[0] = ~scl_drive_low; // Command: 1 means FPGA releases SCL.
    assign led[1] = scl_sync[1];   // Actual SCL pad level.
    assign led[2] = sda_sync[1];   // Actual SDA pad level; should stay high.
    assign led[3] = scl_drive_low; // Command: 1 means FPGA drives SCL low.
    assign led[7:4] = 4'b0000;
endmodule
