module demux( // Demux con 4 entradas
	input wire [1:0] sel,      
	input wire [2:0] btn,
	output reg [2:0] btn_clock,
	output reg [2:0] btn_alarm,
	output reg [2:0] btn_cron,
	output reg [2:0] btn_temp
);

// Selector 
always @(*) begin
	case (sel) 
			4'b00: btn_clock = btn; 
			4'b01: btn_alarm = btn;
			4'b10: btn_cron = btn;
			4'b11: btn_temp = btn;
		endcase 
	end
	
endmodule


