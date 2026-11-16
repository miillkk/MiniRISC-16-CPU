`timescale 1ns/1ps

module font5x7 (
    input  wire [7:0] character,
    input  wire [2:0] row,
    input  wire [2:0] column,
    output wire       pixel_on
);
    reg [4:0] row_bits;
    always @* begin
        row_bits = 5'b00000;
        case (character)
            "0": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10001;2:row_bits=5'b10011;3:row_bits=5'b10101;4:row_bits=5'b11001;5:row_bits=5'b10001;6:row_bits=5'b01110;default:row_bits=0;endcase
            "1": case(row) 0:row_bits=5'b00100;1:row_bits=5'b01100;2:row_bits=5'b00100;3:row_bits=5'b00100;4:row_bits=5'b00100;5:row_bits=5'b00100;6:row_bits=5'b01110;default:row_bits=0;endcase
            "2": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10001;2:row_bits=5'b00001;3:row_bits=5'b00010;4:row_bits=5'b00100;5:row_bits=5'b01000;6:row_bits=5'b11111;default:row_bits=0;endcase
            "3": case(row) 0:row_bits=5'b11110;1:row_bits=5'b00001;2:row_bits=5'b00001;3:row_bits=5'b01110;4:row_bits=5'b00001;5:row_bits=5'b00001;6:row_bits=5'b11110;default:row_bits=0;endcase
            "4": case(row) 0:row_bits=5'b00010;1:row_bits=5'b00110;2:row_bits=5'b01010;3:row_bits=5'b10010;4:row_bits=5'b11111;5:row_bits=5'b00010;6:row_bits=5'b00010;default:row_bits=0;endcase
            "5": case(row) 0:row_bits=5'b11111;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b11110;4:row_bits=5'b00001;5:row_bits=5'b00001;6:row_bits=5'b11110;default:row_bits=0;endcase
            "6": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b11110;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b01110;default:row_bits=0;endcase
            "7": case(row) 0:row_bits=5'b11111;1:row_bits=5'b00001;2:row_bits=5'b00010;3:row_bits=5'b00100;4:row_bits=5'b01000;5:row_bits=5'b01000;6:row_bits=5'b01000;default:row_bits=0;endcase
            "8": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b01110;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b01110;default:row_bits=0;endcase
            "9": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b01111;4:row_bits=5'b00001;5:row_bits=5'b00001;6:row_bits=5'b01110;default:row_bits=0;endcase
            "A": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b11111;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b10001;default:row_bits=0;endcase
            "C": case(row) 0:row_bits=5'b01111;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b10000;4:row_bits=5'b10000;5:row_bits=5'b10000;6:row_bits=5'b01111;default:row_bits=0;endcase
            "D": case(row) 0:row_bits=5'b11110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b10001;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b11110;default:row_bits=0;endcase
            "E": case(row) 0:row_bits=5'b11111;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b11110;4:row_bits=5'b10000;5:row_bits=5'b10000;6:row_bits=5'b11111;default:row_bits=0;endcase
            "G": case(row) 0:row_bits=5'b01111;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b10111;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b01111;default:row_bits=0;endcase
            "H": case(row) 0:row_bits=5'b10001;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b11111;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b10001;default:row_bits=0;endcase
            "I": case(row) 0:row_bits=5'b11111;1:row_bits=5'b00100;2:row_bits=5'b00100;3:row_bits=5'b00100;4:row_bits=5'b00100;5:row_bits=5'b00100;6:row_bits=5'b11111;default:row_bits=0;endcase
            "L": case(row) 0:row_bits=5'b10000;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b10000;4:row_bits=5'b10000;5:row_bits=5'b10000;6:row_bits=5'b11111;default:row_bits=0;endcase
            "M": case(row) 0:row_bits=5'b10001;1:row_bits=5'b11011;2:row_bits=5'b10101;3:row_bits=5'b10101;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b10001;default:row_bits=0;endcase
            "O": case(row) 0:row_bits=5'b01110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b10001;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b01110;default:row_bits=0;endcase
            "P": case(row) 0:row_bits=5'b11110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b11110;4:row_bits=5'b10000;5:row_bits=5'b10000;6:row_bits=5'b10000;default:row_bits=0;endcase
            "R": case(row) 0:row_bits=5'b11110;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b11110;4:row_bits=5'b10100;5:row_bits=5'b10010;6:row_bits=5'b10001;default:row_bits=0;endcase
            "S": case(row) 0:row_bits=5'b01111;1:row_bits=5'b10000;2:row_bits=5'b10000;3:row_bits=5'b01110;4:row_bits=5'b00001;5:row_bits=5'b00001;6:row_bits=5'b11110;default:row_bits=0;endcase
            "T": case(row) 0:row_bits=5'b11111;1:row_bits=5'b00100;2:row_bits=5'b00100;3:row_bits=5'b00100;4:row_bits=5'b00100;5:row_bits=5'b00100;6:row_bits=5'b00100;default:row_bits=0;endcase
            "U": case(row) 0:row_bits=5'b10001;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b10001;4:row_bits=5'b10001;5:row_bits=5'b10001;6:row_bits=5'b01110;default:row_bits=0;endcase
            "V": case(row) 0:row_bits=5'b10001;1:row_bits=5'b10001;2:row_bits=5'b10001;3:row_bits=5'b10001;4:row_bits=5'b10001;5:row_bits=5'b01010;6:row_bits=5'b00100;default:row_bits=0;endcase
            default: row_bits = 5'b00000;
        endcase
    end
    assign pixel_on = (column < 5) ? row_bits[4-column] : 1'b0;
endmodule
