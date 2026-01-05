module decoder_esp ( // decoder para am/pm utilizando los flags del reloj
	input flag_pm,
	input flag_24h,
	output reg [6:0] seg_0,
	output reg [6:0] seg_1
);

always @(*) begin 
	if (flag_24h) begin
		seg_0 = 7'b0001001;
		seg_1 = 7'b0101111;
	end else begin 
		case(flag_pm)
			1'b0: begin
			seg_0 = 7'b0001000; 
			seg_1 = 7'b0101011;
			end
			1'b1: begin
			seg_0 = 7'b0001100;
			seg_1 = 7'b0101011;
			end
	 endcase
	end
end

endmodule