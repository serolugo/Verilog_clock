module bcd_down_00_99(
	input wire clk,
	input wire rst,      
	input wire en,       
	input wire load, // carga síncrona
	input wire [3:0] tens_in,
	input wire [3:0] ones_in,
	output reg [3:0] tens,
	output reg [3:0] ones,
	output reg borrow
);
always @(posedge clk) begin
  if (rst) begin
		tens <= 4'd0;
		ones <= 4'd0;
		borrow <= 1'b0;
  end else if (load) begin
		tens <= tens_in;
		ones <= ones_in;
		borrow <= 1'b0;
  end else if (en) begin
		if (tens == 4'd0 && ones == 4'd0) begin
			 tens <= 4'd9;
			 ones <= 4'd9;
			 borrow <= 1'b1;
		end else if (ones == 4'd0) begin
			 ones <= 4'd9;
			 tens <= tens - 4'd1;
			 borrow <= 1'b0;
		end else begin
			 ones <= ones - 4'd1;
			 borrow <= 1'b0;
		end
  end else begin
		borrow <= 1'b0;
  end
end


endmodule


