module seven_seg_decoder #(
    parameter comun = 1'b0  // 0 para catodo comun, 1 para anodo comun
)( 
	input [3:0] data_in, 
	output [6:0] seg 
); 

reg [6:0] seg_raw;
  
always @(*) begin 
	case (data_in) 
		4'd0: seg_raw = 7'b1000000; 
		4'd1: seg_raw = 7'b1111001; 
		4'd2: seg_raw = 7'b0100100; 
		4'd3: seg_raw = 7'b0110000; 
		4'd4: seg_raw = 7'b0011001; 
		4'd5: seg_raw = 7'b0010010; 
		4'd6: seg_raw = 7'b0000010; 
		4'd7: seg_raw = 7'b1111000; 
		4'd8: seg_raw = 7'b0000000; 
		4'd9: seg_raw = 7'b0010000; 
		default: seg_raw = 7'b1111111; 
	endcase 
end 
	
assign seg = comun ? ~seg_raw : seg_raw;

endmodule