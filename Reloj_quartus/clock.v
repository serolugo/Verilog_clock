module clock #(
// parámetros de hora y formato de inicio
parameter integer INIT_HH = 12,  // hora de inicio 
parameter integer INIT_MM = 0,   // minutos de inicio 
parameter integer INIT_SS = 0,   // segundos de inicio
parameter INIT_IS_24H = 1'b0 // 1 para 24 hrs, 0 para 12 horas
)(
	input wire clk,         // 50 MHz
	input wire clk_1hz,     // 1 Hz
	input wire clk_3hz,     // 3 Hz para blink
	input wire reset,       // activo en bajo
	input wire [2:0] btn,  
	// salidas
	output wire [3:0] horas_decenas,
	output wire [3:0] horas_unidades,
	output wire [3:0] minutos_decenas,
	output wire [3:0] minutos_unidades,
	output wire [3:0] segundos_decenas,
	output wire [3:0] segundos_unidades,
	output wire flag_pm,     // 1 = PM, 0 = AM
	output wire flag_24h     // 1 = 24h, 0 = 12h
);

wire rst = ~reset;

// Sincronizacion con clk_1hz
reg clk1hz_ff0, clk1hz_ff1;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		clk1hz_ff0 <= 1'b0;
		clk1hz_ff1 <= 1'b0;
  end else begin
		clk1hz_ff0 <= clk_1hz;
		clk1hz_ff1 <= clk1hz_ff0;
  end
end

// Pulso de 1 ciclo de 50 MHz en el flanco de subida del clk_1hz
wire tick_1hz_pos = clk1hz_ff0 & ~clk1hz_ff1;

// Sincronizacion del reloj de 3hz
reg clk3hz_ff0, clk3hz_ff1;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		clk3hz_ff0 <= 1'b0;
		clk3hz_ff1 <= 1'b0;
  end else begin
		clk3hz_ff0 <= clk_3hz;
		clk3hz_ff1 <= clk3hz_ff0;
  end
end

wire tick_3hz_pos = clk3hz_ff0 & ~clk3hz_ff1;  // pulso de subida 3 Hz

// Sincronizacion de botones
reg [2:0] btn_ff0, btn_ff1;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		btn_ff0 <= 3'b111;
		btn_ff1 <= 3'b111;
  end else begin
		btn_ff0 <= btn;
		btn_ff1 <= btn_ff0;
  end
end

wire [2:0] btn_press = btn_ff1 & ~btn_ff0;

wire btn0_press = btn_press[0]; // cambio 12/24h
wire btn1_press = btn_press[1]; // cambio modo de ajuste
wire btn2_press = btn_press[2]; // +1 (minuto/hora según modo)

// selector de formato de hora
reg [1:0] set_mode;
reg       is_24h_reg;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		set_mode   <= 2'b00;
		is_24h_reg <= INIT_IS_24H;
  end else begin
		// Cambia modo con btn[1]
		if (btn1_press) begin
			 case (set_mode)
				  2'b00: set_mode <= 2'b01; // normal -> ajustar minutos
				  2'b01: set_mode <= 2'b10; // ajustar minutos -> ajustar horas
				  default: set_mode <= 2'b00; // ajustar horas -> normal
			 endcase
		end

		// cambio de formato 12/24h con btn[0]
		if (btn0_press) begin
			 is_24h_reg <= ~is_24h_reg;
		end
  end
end

 assign flag_24h = is_24h_reg;

 wire normal_mode  = (set_mode == 2'b00);
 wire adjust_min   = (set_mode == 2'b01);
 wire adjust_hour  = (set_mode == 2'b10);

// Blink con 3 hz 
reg blink;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		blink <= 1'b1;
  end else begin
		if (set_mode == 2'b00) begin
			 blink <= 1'b1; // sin parpadeo en modo normal
		end else begin
			 if (tick_3hz_pos)
				  blink <= ~blink;
		end
  end
end

// Pulsos de incremento manual
wire inc_minute = adjust_min  & btn2_press;
wire inc_hour   = adjust_hour & btn2_press;

// Contadores BCD en cascada 
wire [3:0] s_tens, s_ones;
wire [3:0] m_tens, m_ones;
wire [3:0] h_tens, h_ones;

wire carry_s, carry_m, carry_h;

// Enable de segundos
wire en_sec = normal_mode ? tick_1hz_pos : 1'b0;

// En minutos: ripple normal (carry_s) SOLO en modo normal + incrementos manuales
wire en_min = (normal_mode ? carry_s : 1'b0) | inc_minute;

// En horas: ripple normal (carry_m) SOLO en modo normal + incrementos manuales
wire en_hour = (normal_mode ? carry_m : 1'b0) | inc_hour;

// Instancia del contador de 0 a 59 para segundos
bcd_counter_00_59 u_sec (
  .clk(clk),
  .rst(rst),
  .en(en_sec),
  .tens(s_tens),
  .ones(s_ones),
  .carry(carry_s)
);

// Instancia del contador de 0 a 59 para minutos
bcd_counter_00_59 u_min (
  .clk(clk),
  .rst(rst),
  .en(en_min),
  .tens(m_tens),
  .ones(m_ones),
  .carry(carry_m)
);

// Instancia del contador de 0 a 23 para horas
bcd_counter_00_23 #(
  .INIT_VAL(INIT_HH)
) u_hour (
  .clk(clk),
  .rst(rst),
  .en(en_hour),
  .tens(h_tens),
  .ones(h_ones),
  .carry(carry_h)
);

// Salidas directas de segundos (
 assign segundos_decenas = s_tens; 
 assign segundos_unidades = s_ones;

// Parpadeo de minutos
reg [3:0] disp_m_tens;
reg [3:0] disp_m_ones;

always @(*) begin
  if (adjust_min && !blink) begin
		disp_m_tens = 4'hF; 
		disp_m_ones = 4'hF;
  end else begin
		disp_m_tens = m_tens;
		disp_m_ones = m_ones;
  end
end

assign minutos_decenas = disp_m_tens;
assign minutos_unidades = disp_m_ones;

// 7) Conversión a 12h a 24h y parpadeo de HORAS

reg [3:0] disp_h_tens;
reg [3:0] disp_h_ones;
reg pm_reg;

integer hour24;
integer hour12;

always @(*) begin
  // Convertimos BCD de horas internas a decimal 
  hour24 = h_tens*10 + h_ones;
  // Flag PM: 1 si hora >= 12
  if (hour24 < 12)
		pm_reg = 1'b0;  // AM
  else
		pm_reg = 1'b1;  // PM
  if (is_24h_reg) begin
		// Formato 24h
		disp_h_tens = h_tens;
		disp_h_ones = h_ones;
  end else begin
		// Formato 12h
		if (hour24 == 0) begin
			 hour12 = 12; // 00 -> 12 AM
		end else if (hour24 <= 12) begin
			 hour12 = hour24; 
		end else begin
			 hour12 = hour24 - 12; // de 24 a 12 h
		end
		disp_h_tens = hour12 / 10;
		disp_h_ones = hour12 % 10;
  end

  // Parpadeo de horas en modo ajuste de horas
  if (adjust_hour && !blink) begin
		disp_h_tens = 4'hF;
		disp_h_ones = 4'hF;
  end
end

assign horas_decenas = disp_h_tens;
assign horas_unidades = disp_h_ones;
assign flag_pm = pm_reg;

endmodule
