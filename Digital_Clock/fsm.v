// Maquina de estados de mealy
module fsm (
    input  wire clk,
    input  wire reset,    
    input  wire btn_3,     
    output reg [1:0] state_out
);

//Estados 
localparam S_CLOCK = 2'b00; // Reloj
localparam S_ALARM = 2'b01; // Alarma
localparam S_CRON = 2'b10; // Cronometro
localparam S_TEMP = 2'b11; // Temp

//Registros de estados
reg [1:0] state;			// Estado actual
reg [1:0] state_n;		// Estado siguiente

// Sincronizacion para el boton
reg btn_3_sync, btn_3_sync_d; 

always @(posedge clk) begin
  if (!reset) begin
		state <= S_CLOCK;
		btn_3_sync <= 1'b1;   
		btn_3_sync_d <= 1'b1;
  end else begin
		state <= state_n;
		btn_3_sync <= btn_3;
		btn_3_sync_d <= btn_3_sync;
  end
end

wire btn_3_press;
assign btn_3_press = btn_3_sync_d & ~btn_3_sync;  

// Logica para el cambio de estado
always @(*) begin
  state_n = state;
  case (state)
		S_CLOCK: begin
			 if (btn_3_press) state_n = S_ALARM;
		end
		S_ALARM: begin
			 if (btn_3_press) state_n = S_CRON;
		end
		S_CRON: begin
			 if (btn_3_press) state_n = S_TEMP;
		end
		S_TEMP: begin
			 if (btn_3_press) state_n = S_CLOCK;
		end
		default: begin
			 state_n = S_CLOCK;
		end
  endcase
end

// outputs estados
always @(*) begin
  state_out = 2'b00; // default
  case (state)
		S_CLOCK: state_out = 2'b00;
		S_ALARM: state_out = 2'b01;
		S_CRON:  state_out = 2'b10;
		S_TEMP:  state_out = 2'b11;
		default: state_out = 2'b00;
  endcase
end

endmodule
