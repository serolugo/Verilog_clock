// seven_seg_decoder.v
// Outputs are ordered as seg[6:0] = {a,b,c,d,e,f,g}
// Active level depends on COMMON_ANODE parameter.

module seven_seg_decoder #(
    parameter COMMON_ANODE = 1'b0  // 0 = Common Cathode (ON=1), 1 = Common Anode (ON=0)
)(
    input  wire [3:0] value,   // 0..F
    input  wire       dp_in,   // decimal point input (1 = ON in CC mode)
    output wire [6:0] seg,     // {a,b,c,d,e,f,g}
    output wire       dp       // decimal point output
);

    // Active-HIGH truth table for HEX (0..F), order = a,b,c,d,e,f,g
    // 1 = segment ON (for CC). We'll invert later if CA.
    reg [6:0] seg_raw;
    always @* begin
        case (value)
            4'h0: seg_raw = 7'b1111110;
            4'h1: seg_raw = 7'b0110000;
            4'h2: seg_raw = 7'b1101101;
            4'h3: seg_raw = 7'b1111001;
            4'h4: seg_raw = 7'b0110011;
            4'h5: seg_raw = 7'b1011011;
            4'h6: seg_raw = 7'b1011111;
            4'h7: seg_raw = 7'b1110000;
            4'h8: seg_raw = 7'b1111111;
            4'h9: seg_raw = 7'b1111011;
            4'hA: seg_raw = 7'b1110111; // 'A'
            4'hB: seg_raw = 7'b0011111; // 'b'
            4'hC: seg_raw = 7'b1001110; // 'C'
            4'hD: seg_raw = 7'b0111101; // 'd'
            4'hE: seg_raw = 7'b1001111; // 'E'
            4'hF: seg_raw = 7'b1000111; // 'F'
            default: seg_raw = 7'b0000000; // blank
        endcase
    end

    // Apply polarity: CC -> as-is; CA -> invert (ON=0)
    assign seg = COMMON_ANODE ? ~seg_raw : seg_raw;
    assign dp  = COMMON_ANODE ? ~dp_in  : dp_in;

endmodule
