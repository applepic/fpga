`timescale 1ns / 1ps

// Acceptance test for tutorial lesson 03 (blinky).
//
// Expected values are hand-derived from the specification in
// examples/tutorial/03_registers/README.md, not recomputed from the design's operators.
//
//   WIDTH = 8, so the counter is 8 bits: after n rising edges it holds n mod 256.
//   o_led = counter[7], so it is 1 for counter 128..255 and 0 for 0..127.
//
//   edge  counter  LED
//     1      1      0
//   127    127      0
//   128    128      1     (the first time the LED is high)
//   255    255      1
//   256      0      0     (the next time it is low)
//   384    128      1     (one full period after edge 128)
//
// The testbench overrides the design's default WIDTH (27) with 8, because at WIDTH = 27 the LED would
// not move for 2^27 edges. A design that ignores its own parameter never toggles here and fails.

module tb;
    localparam WIDTH = 8;
    localparam EDGES = 400;

    reg  i_clk;
    wire o_led;
    reg  last_led;

    blinky #(.WIDTH(WIDTH)) u_dut(.i_clk(i_clk), .o_led(o_led));

    integer edges;
    integer errors;

    always #5 i_clk = ~i_clk;

    task apply_edge;
        begin
            @(posedge i_clk);
            #1;
            edges = edges + 1;
        end
    endtask

    task check_led(input integer at, input reg want);
        begin
            if (edges == at) begin
                if (o_led !== want) begin
                    $display("FAIL edge %0d: LED is %0d, expected %0d", at, o_led, want);
                    errors = errors + 1;
                end else
                    $display("ok   edge %0d: LED = %0d", at, o_led);
            end
        end
    endtask

    initial begin
        errors   = 0;
        edges    = 0;
        i_clk    = 0;
        last_led = 1'b1;

        apply_edge;
        if (u_dut.counter !== 8'd1) begin
            $display("FAIL start: counter is %0d after one edge, expected 1", u_dut.counter);
            $display("     (the design must set counter to 0 at time 0 with `initial counter = 0;`)");
            errors = errors + 1;
        end else
            $display("ok   start: counter = 1 after one edge, so it started at 0");

        while (edges < EDGES) begin
            last_led = o_led;
            apply_edge;
            if (o_led !== last_led)
                $display("     LED changed at edge %0d", edges);
            check_led(127, 1'b0);
            check_led(128, 1'b1);
            check_led(255, 1'b1);
            check_led(256, 1'b0);
            check_led(384, 1'b1);
        end

        if (errors == 0) $display("=== tb PASS === blinky with WIDTH = %0d", WIDTH);
        else             $display("=== tb FAIL === %0d problem(s)", errors);
        $finish;
    end
endmodule
