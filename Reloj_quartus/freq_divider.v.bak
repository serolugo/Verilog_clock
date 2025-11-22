module freq_divider #(
    parameter integer FREQ_IN_HZ  = 100_000_000, // Paramtro del reloj de entrada
    parameter integer FREQ_OUT_HZ = 50_000_000      // Parametro del reloj de salida
)(
    input  wire clk_in,     // Reloj de entrada
    input  wire reset,      // reset
    output reg  clk_out     // Reloj de salida
);
    // Para cuadrada a F_OUT, necesitamos togglear 2*F_OUT veces por segundo
    localparam integer INCR = 2*FREQ_OUT_HZ;
    
    // Usa 64 bits para evitar desbordes con Fclk altos
    reg  [63:0] acc = 64'd0;
    wire [63:0] next_acc = acc + INCR;
    // Igualamos anchos con una constante de 64 bits
    localparam [63:0] F_IN_64 = FREQ_IN_HZ;
    
    // Divisor
    always @(posedge clk_in) begin
        if (!reset) begin
            acc     <= 64'd0;
            clk_out <= 1'b0;
        end else begin 
            if (next_acc >= F_IN_64) begin
                acc     <= next_acc - F_IN_64; // "wrap"
                clk_out <= ~clk_out;           // toggle → salida 
            end else begin
                acc     <= next_acc;
            end
        end
    end
    
endmodule
