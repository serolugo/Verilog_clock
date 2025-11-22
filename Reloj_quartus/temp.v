module temp(
	input wire clk, 			// 50 MHz
	input wire reset,      
	input wire [2:0] btn,	// btn_0: start/stop, btn_1: reset_temp, btn_2: subir
	input wire clk_1khz,   	// 1 kHz
	
	output wire [3:0] min_tens,
	output wire [3:0] min_ones,
	output wire [3:0] sec_tens,
	output wire [3:0] sec_ones,
	output wire [3:0] ms_tens,
	output wire [3:0] ms_ones,
	output reg flag_done 
	);
	
wire rst = ~reset;

// Sincronizacion de clk_1khz con clk
reg k1_ff0, k1_ff1;
always @(posedge clk) begin
  if (rst) begin
		k1_ff0 <= 1'b0;
		k1_ff1 <= 1'b0;
  end else begin
		k1_ff0 <= clk_1khz;
		k1_ff1 <= k1_ff0;
  end
end

wire tick_1khz_pos = k1_ff0 & ~k1_ff1;

// Divisor para centemsimas
reg [3:0] div10;
wire tick_100hz = (div10 == 4'd9) & tick_1khz_pos;

always @(posedge clk) begin
  if (rst) begin
		div10 <= 4'd0;
  end else if (tick_1khz_pos) begin
		if (div10 == 4'd9)
			 div10 <= 4'd0;
		else
			 div10 <= div10 + 4'd1;
  end
end

// Sincronizacion de botones
reg [1:0] btn0_sync;
always @(posedge clk) begin
  if (rst)
		btn0_sync <= 2'b11;
  else
		btn0_sync <= {btn0_sync[0], btn[0]};
end
wire btn0_fall = btn0_sync[1] & ~btn0_sync[0]; // start/stop

reg [1:0] btn1_sync;
always @(posedge clk) begin
  if (rst)
		btn1_sync <= 2'b11;
  else
		btn1_sync <= {btn1_sync[0], btn[1]};
end
wire btn1_fall = btn1_sync[1] & ~btn1_sync[0]; // reset_temp

reg [1:0] btn2_sync;
always @(posedge clk) begin
  if (rst)
		btn2_sync <= 2'b11;
  else
		btn2_sync <= {btn2_sync[0], btn[2]};
end
wire btn2_fall = btn2_sync[1] & ~btn2_sync[0]; // subir minutos

// flag del temperoizador interno
    reg timer_run;

// Salidas internas de los contadores

wire time_is_zero =
  (min_tens == 4'd0) &&
  (min_ones == 4'd0) &&
  (sec_tens == 4'd0) &&
  (sec_ones == 4'd0) &&
  (ms_tens  == 4'd0) &&
  (ms_ones  == 4'd0);

// Control de start/styp y flag (no ha funcionado, creemos que no lo lee el el del modulo buzzer)
always @(posedge clk) begin
  if (rst) begin
		timer_run <= 1'b0;
		flag_done <= 1'b0;
  end else begin
		// reset_temp → detener y limpiar flag_done
		if (btn1_fall) begin
			 timer_run <= 1'b0;
			 flag_done <= 1'b0;
		end
		// start/stop solo si el tiempo es != 0
		if (btn0_fall && !time_is_zero) begin
			 timer_run <= ~timer_run;
			 // si arrancamos de nuevo el timer, limpiar flag_done
			 if (!timer_run)
				  flag_done <= 1'b0;
		end
		// al subir minutos en reposo, limpiar flag_done
		if (btn2_fall && !timer_run) begin
			 flag_done <= 1'b0;
		end
		// Auto-stop cuando llegamos a 00:00:00 (después del último tick)
		if (timer_run && tick_100hz) begin
			 // Estamos en 00:00:01 → siguiente tick será 00:00:00
			 if ( (min_tens == 4'd0) && (min_ones == 4'd0) &&
					(sec_tens == 4'd0) && (sec_ones == 4'd0) &&
					(ms_tens  == 4'd0) && (ms_ones  == 4'd1) ) begin
				  timer_run <= 1'b0;
				  flag_done <= 1'b1;
			 end
		end
  end
end

//Contadores en cascada
// Enable centrado en centésimas (solo cuando no estamos en cero)
wire en_cs = timer_run & tick_100hz & ~time_is_zero;

// Borrow entre contadores
wire borrow_cs;
wire borrow_s;

// Señales de carga (load) para poner a 0 segundos y centésimas
wire load_cs  = btn1_fall | (btn2_fall & ~timer_run); // reset_temp o ajuste de minutos
wire load_sec = btn1_fall | (btn2_fall & ~timer_run);

// Para minutos: podemos cargar 00 o "minutos + 1"
wire load_min_reset = btn1_fall;            // reset_temp -> 00
wire load_min_set   = btn2_fall & ~timer_run; // subir minutos en reposo

// Cálculo de minutos + 1 (en BCD, 00–59)
reg [3:0] min_plus_tens;
reg [3:0] min_plus_ones;

always @(*) begin
  // por defecto, mismos valores
  min_plus_tens = min_tens;
  min_plus_ones = min_ones;

  if (min_ones == 4'd9) begin
		min_plus_ones = 4'd0;
		if (min_tens == 4'd5)
			 min_plus_tens = 4'd0;
		else
			 min_plus_tens = min_tens + 4'd1;
  end else begin
		min_plus_ones = min_ones + 4'd1;
  end
end

wire load_min = load_min_reset | load_min_set;
wire [3:0] min_load_tens = load_min_reset ? 4'd0 : load_min_set ? min_plus_tens : 4'd0; // no importa cuando load_min=0
wire [3:0] min_load_ones = load_min_reset ? 4'd0 : load_min_set ? min_plus_ones : 4'd0;

// Instancia dle contador de 99 a 0
bcd_down_00_99 u_cs (
	.clk(clk),
	.rst(rst),
	.en(en_cs),
	.load(load_cs),
	.tens_in(4'd0),
	.ones_in(4'd0),
	.tens(ms_tens),
	.ones(ms_ones),
	.borrow(borrow_cs)
);

// Instancia del contador de 59 a 0 para segundos
 bcd_down_00_59 u_sec (
	.clk(clk),
	.rst(rst),
	.en(borrow_cs),
	.load(load_sec),
	.tens_in(4'd0),
	.ones_in(4'd0),
	.tens(sec_tens),
	.ones(sec_ones),
	.borrow(borrow_s)
 );
	 
// Instancia del contador de 59 a 0 para minutos-
bcd_down_00_59 u_min (
	.clk(clk),
	.rst(rst),
	.en(borrow_s),
	.load(load_min),
	.tens_in(min_load_tens),
	.ones_in(min_load_ones),
	.tens(min_tens),
	.ones(min_ones),
	.borrow()
);

endmodule



