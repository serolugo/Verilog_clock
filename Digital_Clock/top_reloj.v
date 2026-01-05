module top_reloj #(
  parameter integer FREQ_1HZ = 1,		// Parametro para reloj de 1 hz, para contador de segundos
  parameter integer FREQ_3HZ = 3,		// parametro para reloj de 3 hz, reloj para parpadeo
  parameter integer FREQ_1kHZ = 1000
	)(
	input clk,		// reloj de 50 mhz
	input reset,	// reset global
	// Botones del sistema
	input btn_3,
	input [2:0] btn,
	//	Displays del sistema
	output [6:0] disp_0,
	output [6:0] disp_1,
	output [6:0] disp_2,
	output [6:0] disp_3,
	output [6:0] disp_4,
	output [6:0] disp_5,
	output [6:0] disp_6,
	output [6:0] disp_7,
	//Leds de sistema
	output wire l0,	// Buzzer simulado, alarma y temporizador
	output wire l1	// Flag de alarma armada
);

// cables de frecuencias lentas
wire clk_1hz;
wire clk_3hz;
wire clk_1khz;

wire [1:0] state;
 
wire [2:0] btn_clock;
wire [2:0] btn_alarm;
wire [2:0] btn_cron;
wire [2:0] btn_temp;

// Divisores de frecuencia
freq_divider #(.FREQ_OUT_HZ(FREQ_1HZ)) divider_1hz( 	//Salida de 1hz
    .clk_in(clk),
    .reset(reset), 
    .clk_out(clk_1hz)
);

freq_divider #(.FREQ_OUT_HZ(FREQ_3HZ)) divider_3hz( //Salida de 3hz
    .clk_in(clk),
    .reset(reset), 
    .clk_out(clk_3hz)
);

freq_divider #(.FREQ_OUT_HZ(FREQ_1kHZ)) divider_1khz( //Salida de 1kz
    .clk_in(clk),
    .reset(reset), 
    .clk_out(clk_1khz)
);

//Instancia demux, de aqui obtenemos los "botones para los modulos"
demux demux(
	.sel(state),
	.btn(btn),
	.btn_clock(btn_clock),
	.btn_alarm(btn_alarm),
	.btn_cron(btn_cron),
	.btn_temp(btn_temp),
);

//Instancia de la maquina de estado
fsm fsm(
	.clk(clk),
	.reset(reset),
	.btn_3(btn_3),
	.state_out(state) // por medio de state obtenemos en 2 bits el estado de la maquina
							// para el mux y el demux
);

//Instancia del modulo de reloj 
wire [3:0]	horas_decenas_clock,
				horas_unidades_clock,
				minutos_decenas_clock,
				minutos_unidades_clock,
				segundos_decenas_clock,
				segundos_unidades_clock;
				
wire flag_pm;
wire flag_24h;

wire [6:0]	disp_2_clock,
				disp_3_clock,
				disp_4_clock,
				disp_5_clock,
				disp_6_clock,
				disp_7_clock,
				seg_pm_0,
				seg_pm_1;

				
clock clock(
	.clk(clk),
	.clk_3hz(clk_3hz),
	.clk_1hz(clk_1hz),
   .reset(reset),
	.btn(btn_clock),
	.horas_decenas(horas_decenas_clock),
	.horas_unidades(horas_unidades_clock),
	.minutos_decenas(minutos_decenas_clock),
	.minutos_unidades(minutos_unidades_clock),
	.segundos_decenas(segundos_decenas_clock),
	.segundos_unidades(segundos_unidades_clock),
	.flag_pm(flag_pm),
	.flag_24h(flag_24h)
);

//Instancias del modulo de la alarma

wire [3:0]	horas_decenas_alarm,
				horas_unidades_alarm,
				minutos_decenas_alarm,
				minutos_unidades_alarm,
				segundos_decenas_alarm,
				segundos_unidades_alarm;
				
wire [6:0]	disp_2_alarm,
				disp_3_alarm,
				disp_4_alarm,
				disp_5_alarm,
				disp_6_alarm,
				disp_7_alarm;
				
wire alarm_flag;
wire flag_alarm_armed;
				
alarm alarm (
	.clk(clk),
	.reset(reset),
	.clk_3hz(clk_3hz),
	.btn(btn_alarm),
	.horas_decenas_in(horas_decenas_clock),
	.horas_unidades_in(horas_unidades_clock),
	.minutos_decenas_in(minutos_decenas_clock),
	.minutos_unidades_in(minutos_unidades_clock),
	.segundos_decenas_in(segundos_decenas_clock),
	.segundos_unidades_in(segundos_unidades_clock),
	.horas_decenas(horas_decenas_alarm),
	.horas_unidades(horas_unidades_alarm),
	.minutos_decenas(minutos_decenas_alarm),
	.minutos_unidades(minutos_unidades_alarm),
	.segundos_decenas(segundos_decenas_alarm),
	.segundos_unidades(segundos_unidades_alarm),
	.flag_alarm(alarm_flag),
	.flag_alarm_armed(flag_alarm_armed)

);

assign l0 = buzzer_wire_alarm; // alarma / buzzer simulado (led porque no tenemos buzzer :( )
assign l1 = flag_alarm_armed; // Saber si esta armado el 
	
//Instancia del módulo del cronómetro

wire [3:0]	minutos_decenas_cron,
				minutos_unidades_cron,
				segundos_decenas_cron,
				segundos_unidades_cron,
				milisegundos_decenas_cron,
				milisegundos_unidades_cron;

wire [6:0]	disp_2_cron,
				disp_3_cron,
				disp_4_cron,
				disp_5_cron,
				disp_6_cron,
				disp_7_cron;
		
cronometer cronometer(
	.clk(clk),
	.reset(reset),
	.clk_1khz(clk_1khz),
	.btn(btn_cron),
	.min_tens(minutos_decenas_cron),
	.min_ones(minutos_unidades_cron),
	.sec_tens(segundos_decenas_cron),
	.sec_ones(segundos_unidades_cron),
	.ms_tens(milisegundos_decenas_cron),
	.ms_ones(milisegundos_unidades_cron)
);

//Instancias del módulo del temporizador

wire [3:0]	minutos_decenas_temp,
				minutos_unidades_temp,
				segundos_decenas_temp,
				segundos_unidades_temp,
				milisegundos_decenas_temp,
				milisegundos_unidades_temp;

wire [6:0]	disp_2_temp,
				disp_3_temp,
				disp_4_temp,
				disp_5_temp,
				disp_6_temp,
				disp_7_temp;
				
				
wire flag_temp_done;		
		
temp temp (
	.clk(clk),
	.reset(reset),
	.clk_1khz(clk_1khz),
	.btn(btn_temp),
	.min_tens(minutos_decenas_temp),
	.min_ones(minutos_unidades_temp),
	.sec_tens(segundos_decenas_temp),
	.sec_ones(segundos_unidades_temp),
	.ms_tens(milisegundos_decenas_temp),
	.ms_ones(milisegundos_unidades_temp),
);		 


//Intancia del modulo buzzer
wire buzzer_wire_alarm;

buzzer buzzer_alarma(
	.clk(clk),
	.clk_3hz(clk_3hz),
	.reset(reset),
	.flag(alarm_flag),
	.buzzer(buzzer_wire_alarm)
);

//Instancias display 0
decoder_esp decorder_esp(
	.flag_pm(flag_pm),
	.flag_24h(flag_24h),
	.seg_0(seg_pm_0),
	.seg_1(seg_pm_1)
);

//Instancias display 1

			/*Instancia display 1 del clock 
			sale del modulo de decoder_esp*/

//Instancias display 2

seven_seg_decoder display_2_clock(
	.data_in(segundos_unidades_clock),
	.seg(disp_2_clock)
);

seven_seg_decoder display_2_cron(
	.data_in(milisegundos_unidades_cron),
	.seg(disp_2_cron)
);
	
seven_seg_decoder display_2_temp(
	.data_in(milisegundos_unidades_temp),
	.seg(disp_2_temp)
);

seven_seg_decoder display_2_alarm(
	.data_in(segundos_unidades_alarm),
	.seg(disp_2_alarm)
);

//Instancias display 3

seven_seg_decoder display_3_clock(
	.data_in(segundos_decenas_clock),
	.seg(disp_3_clock)

);

seven_seg_decoder display_3_cron(
	.data_in(milisegundos_decenas_cron),
	.seg(disp_3_cron)
);

seven_seg_decoder display_3_temp(
	.data_in(milisegundos_decenas_temp),
	.seg(disp_3_temp)
);

seven_seg_decoder display_3_alarm(
	.data_in(segundos_decenas_alarm),
	.seg(disp_3_alarm)
);

//Instancias display 4

seven_seg_decoder display_4_clock(
	.data_in(minutos_unidades_clock),
	.seg(disp_4_clock)
);

seven_seg_decoder display_4_cron(
	.data_in(segundos_unidades_cron),
	.seg(disp_4_cron)
);

seven_seg_decoder display_4_temp(
	.data_in(segundos_unidades_temp),
	.seg(disp_4_temp)
);

seven_seg_decoder display_4_alarm(
	.data_in(minutos_unidades_alarm),
	.seg(disp_4_alarm)
);

//Instancias display 5

seven_seg_decoder display_5_clock(
	.data_in(minutos_decenas_clock),
	.seg(disp_5_clock)
);

seven_seg_decoder display_5_cron(
	.data_in(segundos_decenas_cron),
	.seg(disp_5_cron)
);

seven_seg_decoder display_5_temp(
	.data_in(segundos_decenas_temp),
	.seg(disp_5_temp)
);

seven_seg_decoder display_5_alarm(
	.data_in(minutos_decenas_alarm),
	.seg(disp_5_alarm)
);
//Instancias display 6

seven_seg_decoder display_6_clock(
	.data_in(horas_unidades_clock),
	.seg(disp_6_clock)
);

seven_seg_decoder display_6_cron(
	.data_in(minutos_unidades_cron),
	.seg(disp_6_cron)
);

seven_seg_decoder display_6_temp(
	.data_in(minutos_unidades_temp),
	.seg(disp_6_temp)
);

seven_seg_decoder display_6_alarm(
	.data_in(horas_unidades_alarm),
	.seg(disp_6_alarm)
);

//Instancias display 7

seven_seg_decoder display_7_clock(
	.data_in(horas_decenas_clock),
	.seg(disp_7_clock)
);

seven_seg_decoder display_7_cron(
	.data_in(minutos_decenas_cron),
	.seg(disp_7_cron)
);

seven_seg_decoder display_7_temp(
	.data_in(minutos_decenas_temp),
	.seg(disp_7_temp)
);

seven_seg_decoder display_7_alarm(
	.data_in(horas_decenas_alarm),
	.seg(disp_7_alarm)
);
	
//Multiplexor display 0
mux mux_disp_0(
.sel(state),
.data_0(seg_pm_1),
.data_1(7'b1000111),
.data_2(7'b0101111),
.data_3(7'b0001100),
.data_out(disp_0)
);


//Multiplexor display 1
mux mux_disp_1(
.sel(state),
.data_0(seg_pm_0),
.data_1(7'b0001000),
.data_2(7'b1000110),
.data_3(7'b0000111),
.data_out(disp_1)
);


//Multiplexor display 2
mux mux_disp_2(
.sel(state),
.data_0(disp_2_clock),
.data_1(disp_2_alarm),
.data_2(disp_2_cron),
.data_3(disp_2_temp),
.data_out(disp_2)
);


//Multiplexor display 3
mux mux_disp_3(
.sel(state),
.data_0(disp_3_clock),
.data_1(disp_3_alarm),
.data_2(disp_3_cron),
.data_3(disp_3_temp),
.data_out(disp_3)
);


//Multiplexor display 4
mux mux_disp_4(
.sel(state),
.data_0(disp_4_clock),
.data_1(disp_4_alarm),
.data_2(disp_4_cron),
.data_3(disp_4_temp),
.data_out(disp_4)
);


//Multiplexor display 5
mux mux_disp_5(
.sel(state),
.data_0(disp_5_clock),
.data_1(disp_5_alarm),
.data_2(disp_5_cron),
.data_3(disp_5_temp),
.data_out(disp_5)
);


//Multiplexor display 6
mux mux_disp_6(
.sel(state),
.data_0(disp_6_clock),
.data_1(disp_6_alarm),
.data_2(disp_6_cron),
.data_3(disp_6_temp),
.data_out(disp_6)
);


//Multiplexor display 7
mux mux_disp_7(
.sel(state),
.data_0(disp_7_clock),
.data_1(disp_7_alarm),
.data_2(disp_7_cron),
.data_3(disp_7_temp),
.data_out(disp_7)
);


endmodule 
