`timescale 1ns / 1ps

// Testbench for exercise 01. This is your acceptance criteria. Do not modify it.
//
// Run:
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/01_counter
//
// It checks three things:
//   1. q = 0 while reset is asserted
//   2. q increments on every rising clock edge
//   3. After 15 it wraps to 0, without stalling or skipping values

module tb;

    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [3:0] q;

    // 27 MHz means a period of about 37 ns. Using 10 ns here just makes simulation fast;
    // counter behaviour does not depend on the clock frequency.
    always #5 clk = ~clk;

    counter u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .q     (q)
    );

    integer errors = 0;
    integer i;
    reg [3:0] expected;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // ---- Check 1: reset ----
        rst_n = 1'b0;
        #22;                        // a little over two clock cycles, enough for reset to take effect
        if (q !== 4'd0) begin
            $display("FAIL check1: q = %0d during reset, expected 0", q);
            errors = errors + 1;
        end
        else begin
            $display("PASS check1: q = 0 during reset");
        end

        // ---- Checks 2 and 3: 20 consecutive cycles, covering the 15 -> 0 wrap ----
        rst_n = 1'b1;
        expected = 4'd0;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);         // wait for the rising edge
            #1;                     // wait 1 ns for the output to settle (avoid a race)
            expected = expected + 4'd1;
            if (q !== expected) begin
                $display("FAIL check2/3: after rising edge %0d, q = %0d, expected %0d",
                         i + 1, q, expected);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("PASS check2/3: all 20 cycles correct (including the 15 -> 0 wrap)");

        // ---- Result ----
        if (errors == 0) $display("\n=== ALL PASS ===");
        else             $display("\n=== %0d mismatch(es), see the FAIL lines above ===", errors);

        $finish;
    end

    // Prevent the simulation from hanging if the design never responds to the clock
    initial begin
        #10000;
        $display("FAIL: simulation timed out; the design may not be responding to the clock");
        $finish;
    end

endmodule
