module mux ( //multiplexor para 4 inputs
    input  wire [6:0] data_0,
	 input  wire [6:0] data_1,
	 input  wire [6:0] data_2,
	 input  wire [6:0] data_3,
    input  wire [1:0] sel,      
    output reg [6:0] data_out            
);

//Selector 
always @(*) begin 
		case (sel) 
			4'b00: data_out = data_0; 
			4'b01: data_out = data_1;
			4'b10: data_out = data_2;
			4'b11: data_out = data_3;
		endcase 
	end 

endmodule
