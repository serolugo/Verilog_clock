module cronometer(
	input wire clk,        // 50 MHz
	input wire reset,      // activo en alto
	input wire clk_1khz,   // 1 kHz
	input wire [2:0] btn,        // btn[0]=start/stop, btn[1]=reset, btn[2]=sin usar
	output wire [3:0] min_tens,
	output wire [3:0] min_ones,
	output wire [3:0] sec_tens,
	output wire [3:0] sec_ones,
	output wire [3:0] ms_tens,
	output wire [3:0] ms_ones
);

wire rst = ~reset | ~btn[1];   

//Sincronizadcion dee clk_1kh con clk
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

// Divisor para centesimas
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

// Sincronizacion boton start
reg [1:0] btn0_sync;
always @(posedge clk) begin
  if (rst)
		btn0_sync <= 2'b11;         // suelto = 1
  else
		btn0_sync <= {btn0_sync[0], btn[0]};
end

wire btn0_fall = btn0_sync[1] & ~btn0_sync[0]; // flanco 1->0

reg chrono_run;
always @(posedge clk) begin
  if (rst) begin
		chrono_run <= 1'b0;
  end else if (btn0_fall) begin
		chrono_run <= ~chrono_run;
  end
end

// Enable general del cronómetro 
wire en_ms = tick_100hz & chrono_run;

// Cascada de contadores
wire carry_ms;
wire carry_s;
wire carry_m;

bcd_counter_00_99 u_ms (
  .clk(clk),
  .rst(rst),
  .en(en_ms),
  .tens(ms_tens),
  .ones(ms_ones),
  .carry(carry_ms)
);

bcd_counter_00_59 u_sec (
  .clk(clk),
  .rst(rst),
  .en(carry_ms),
  .tens(sec_tens),
  .ones(sec_ones),
  .carry(carry_s)
);

bcd_counter_00_59 u_min (
  .clk(clk),
  .rst(rst),
  .en(carry_s),
  .tens(min_tens),
  .ones(min_ones),
  .carry (carry_m)  
);

endmodule


