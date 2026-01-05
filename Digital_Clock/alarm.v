module alarm(
	input wire clk,			// 50 MHz
	input wire clk_3hz,		// reloj 3 Hz para blink
	input wire reset,			
	input wire [2:0] btn,	// btn0=subir, btn1=cambiar campo, btn2=set alarm
	// hora actual en BCD (desde clock)
	input wire [3:0] horas_decenas_in,
	input wire [3:0] horas_unidades_in,
	input wire [3:0] minutos_decenas_in,
	input wire [3:0] minutos_unidades_in,
	input wire [3:0] segundos_decenas_in,
	input wire [3:0] segundos_unidades_in,
	// hora programada de alarma (BCD) hacia el display
	output wire [3:0] horas_decenas,
	output wire [3:0] horas_unidades,
	output wire [3:0] minutos_decenas,
	output wire [3:0] minutos_unidades,
	output wire [3:0] segundos_decenas,
	output wire [3:0] segundos_unidades,
	
	output wire flag_alarm, 		// match de hora actual con alarma
	output wire flag_alarm_armed 	// 1 = alarma armada
);

wire rst = ~reset;

// Sincronizacion de botones
reg [2:0] btn_ff0, btn_ff1;

always @(posedge clk or negedge reset) begin
  if(!reset) begin
		btn_ff0 <= 3'b111;
		btn_ff1 <= 3'b111;
  end else begin
		btn_ff0 <= btn;
		btn_ff1 <= btn_ff0;
  end
end

wire btn0_press = btn_ff1[0] & ~btn_ff0[0]; // subir unidades
wire btn1_press = btn_ff1[1] & ~btn_ff0[1]; // cambiar campo
wire btn2_press = btn_ff1[2] & ~btn_ff0[2]; // set alarm (toggle)

// Sincronizacion clk_3hz con clk 
reg clk3_ff0, clk3_ff1;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		clk3_ff0 <= 1'b0;
		clk3_ff1 <= 1'b0;
  end else begin
		clk3_ff0 <= clk_3hz;
		clk3_ff1 <= clk3_ff0;
  end
end

wire tick_3hz_pos = clk3_ff0 & ~clk3_ff1;

reg blink;

always @(posedge clk or negedge reset) begin
  if (!reset) begin
		blink <= 1'b1;
  end else begin
		if (tick_3hz_pos)
			 blink <= ~blink;
  end
end

// Registros de la hora definida
reg [3:0] alarm_h_t;
reg [3:0] alarm_h_o;
reg [3:0] alarm_m_t;
reg [3:0] alarm_m_o;
reg [3:0] alarm_s_t;
reg [3:0] alarm_s_o;

// Selector
reg [1:0] sel;

// enable de la alarma (armada)
reg alarm_enable;

// Secuencia selector 
always @(posedge clk or negedge reset) begin
  if(!reset) begin
		alarm_h_t <= 4'd0;
		alarm_h_o <= 4'd0;
		alarm_m_t <= 4'd0;
		alarm_m_o <= 4'd0;
		alarm_s_t <= 4'd0;
		alarm_s_o <= 4'd0;
		sel <= 2'd0;
		alarm_enable <= 1'b0;
  end else begin
		// cambiar seleccion
		if(btn1_press) begin
			 case(sel)
				  2'd0: sel <= 2'd1;    // seg -> min
				  2'd1: sel <= 2'd2;    // min -> hour
				  default: sel <= 2'd0; // hour -> seg
			 endcase
		end
		// toggle alarm enable 
		if(btn2_press)
			 alarm_enable <= ~alarm_enable;
		// incrementar campo seleccionado
		if(btn0_press) begin
			 case(sel)
				  2'd0: begin // SEGUNDOS
						if(alarm_s_o == 4'd9) begin
							 alarm_s_o <= 4'd0;
							 if(alarm_s_t == 4'd5)
								  alarm_s_t <= 4'd0;
							 else
								  alarm_s_t <= alarm_s_t + 4'd1;
						end else begin
							 alarm_s_o <= alarm_s_o + 4'd1;
						end
				  end

				  2'd1: begin // MINUTOS 
						if(alarm_m_o == 4'd9) begin
							 alarm_m_o <= 4'd0;
							 if(alarm_m_t == 4'd5)
								  alarm_m_t <= 4'd0;
							 else
								  alarm_m_t <= alarm_m_t + 4'd1;
						end else begin
							 alarm_m_o <= alarm_m_o + 4'd1;
						end
				  end

				  2'd2: begin // HORAS
						if(alarm_h_t == 4'd2 && alarm_h_o == 4'd3) begin
							 alarm_h_t <= 4'd0;
							 alarm_h_o <= 4'd0;
						end else if(alarm_h_o == 4'd9) begin
							 alarm_h_o <= 4'd0;
							 alarm_h_t <= alarm_h_t + 4'd1;
						end else begin
							 alarm_h_o <= alarm_h_o + 4'd1;
						end
				  end
			 endcase
		end
  end
end

// parpade horas
reg [3:0] disp_h_t;
reg [3:0] disp_h_o;
reg [3:0] disp_m_t;
reg [3:0] disp_m_o;
reg [3:0] disp_s_t;
reg [3:0] disp_s_o;

always @(*) begin
  // por defecto, mostrar la hora de alarma tal cual
disp_h_t = alarm_h_t;
disp_h_o = alarm_h_o;
disp_m_t = alarm_m_t;
disp_m_o = alarm_m_o;
disp_s_t = alarm_s_t;
disp_s_o = alarm_s_o;
  // parpadeo según campo seleccionado
  case (sel)
		2'd0: begin // segundos
			 if (!blink) begin
				  disp_s_t = 4'hF;
				  disp_s_o = 4'hF;
			 end
		end
		2'd1: begin // minutos
			 if (!blink) begin
				  disp_m_t = 4'hF;
				  disp_m_o = 4'hF;
			 end
		end
		2'd2: begin // horas
			 if (!blink) begin
				  disp_h_t = 4'hF;
				  disp_h_o = 4'hF;
			 end
		end
  endcase
end

// Conexión a salidas
assign horas_decenas = disp_h_t;
assign horas_unidades = disp_h_o;
assign minutos_decenas = disp_m_t;
assign minutos_unidades = disp_m_o;
assign segundos_decenas = disp_s_t;
assign segundos_unidades= disp_s_o;

// Flasgs
assign flag_alarm_armed = alarm_enable;

// flag de coincidencia de hora (comparador)
assign flag_alarm =
  alarm_enable &&
  (horas_decenas_in == alarm_h_t) &&
  (horas_unidades_in == alarm_h_o) &&
  (minutos_decenas_in == alarm_m_t) &&
  (minutos_unidades_in == alarm_m_o) &&
  (segundos_decenas_in == alarm_s_t) &&
  (segundos_unidades_in== alarm_s_o);

endmodule

