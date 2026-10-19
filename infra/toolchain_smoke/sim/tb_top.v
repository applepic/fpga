`timescale 1ns / 1ps

// Testbench for the toolchain self-test: proves the simulation path works too.
//
// It does one thing: toggles clk and prints every bit of led.
// All ones means all LEDs off, which is the intent of the design.

module tb;

    reg clk = 1'b0;

    // 27 MHz means a 37.037 ns period. Rounded to 37 ns here; the error is negligible.
    always #18.5 clk = ~clk;

    wire [5:0] led;

    top u_top (
        .clk (clk),
        .led (led)
    );

    integer errors = 0;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        #100;
        $display("led = %b (expected 111111)", led);
        if (led !== 6'b111111) begin
            $display("FAIL: led is not all ones");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: toolchain self-test passed");
        else             $display("FAIL: %0d mismatch(es)", errors);

        $finish;
    end

endmodule
