module buzzer ( 
	input wire clk,       // NO se usa, solo está en el header
	input wire clk_3hz,   // reloj de 3 Hz para el parpadeo
	input wire reset,     // activo en bajo
	input wire flag,      // flag de alarma (entrada)
	output reg buzzer     // salida al LED/buzzer
);

// Parámetro duración del blink

parameter integer N_SECONDS = 5;
localparam integer TICKS_PER_SEC = 3;
localparam integer MAX_TICKS = N_SECONDS * TICKS_PER_SEC;

// Sincronizacion clk_3hz con clk
reg flag_ff0, flag_ff1;

wire flag_rise = flag_ff1 & ~flag_ff0; 

// Logica blink
reg active;         
reg [9:0] tick_count;    

always @(posedge clk_3hz or negedge reset) begin
  if (!reset) begin
		flag_ff0 <= 1'b0;
		flag_ff1 <= 1'b0;
		active <= 1'b0;
		tick_count <= 10'd0;
		buzzer <= 1'b0;
  end else begin
		flag_ff0 <= flag;
		flag_ff1 <= flag_ff0;
		if (active) begin
			 buzzer <= ~buzzer;  // toggle cada flanco de 3 Hz
			 if (tick_count == (MAX_TICKS - 1)) begin //Detener despues de los segundos programados
				  active <= 1'b0;
				  tick_count <= 10'd0;
				  buzzer <= 1'b0; // apagar al terminar
			 end else begin
				  tick_count <= tick_count + 10'd1;
			 end
		end else begin
			 buzzer <= 1'b0;
			 tick_count <= 10'd0;
			 if (flag_rise) begin
				  active <= 1'b1;
				  buzzer <= 1'b1;   
				  tick_count <= 10'd0;
			 end
		end
  end
end

endmodule

