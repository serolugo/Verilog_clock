// Simple synchronous debouncer for FPGA buttons
module debounce_sync #(
    // WIDTH = número de bits del contador.
    // Para clk = 50 MHz:
    //   WIDTH = 19 -> ~10.5 ms de debounce (2^19 / 50e6)
    //   WIDTH = 20 -> ~21 ms
    parameter integer WIDTH = 19   // AJUSTADO para 50 MHz
)(
    input  wire clk,    // system clock
    input  wire reset,  // synchronous reset
    input  wire din,    // noisy input
    output reg  dout    // clean output
);
    reg din_sync0, din_sync1;       // input synchronizers
    reg [WIDTH-1:0] cnt;           // debounce counter

    always @(posedge clk) begin
        if (reset) begin
            din_sync0 <= 1'b0;
            din_sync1 <= 1'b0;
        end else begin
            din_sync0 <= din;
            din_sync1 <= din_sync0;
        end
    end

    // Debounce counter
    always @(posedge clk) begin
        if (reset) begin
            cnt  <= {WIDTH{1'b0}};
            dout <= 1'b0;
        end else begin
            if (din_sync1 == dout) begin
                // No change: reset counter
                cnt <= {WIDTH{1'b0}};
            end else begin
                // Possible change: count
                cnt <= cnt + 1'b1;
                if (&cnt) begin
                    // Counter overflow = input stable long enough
                    dout <= din_sync1;
                    cnt  <= {WIDTH{1'b0}};
                end
            end
        end
    end
endmodule
