// For toolchain self-test only. Not learning material.
//
// The only job of this design is to prove the whole chain works
// (synthesis -> place and route -> packing -> programming) before you write your first line
// of your own Verilog.
// If it passes, the toolchain is fine and any later failure is your code or your constraints.
// If it fails, do not go editing code. Come back and investigate the toolchain.
//
// Behaviour: all six LEDs off (the board LEDs are active low, so outputting 1 means off).

module top (
    input  wire       clk,      // 27 MHz; wired in so place and route has a clock to work with
    output wire [5:0] led
);

    // All off. Active low, so output all ones.
    assign led = 6'b111111;

endmodule
