`timescale 1ns / 1ps

// Acceptance test for tutorial lesson 03 (pps).
//
// Every expected value is hand-derived from the specification in
// examples/tutorial/03_pps/README.md, not recomputed from the design's operators.
//
// With CLOCK_RATE_HZ = 27_000_000: D = 13_500_000 and INCREMENT = 2^32 - 13_500_000 = 4_281_467_296.
// The counter adds INCREMENT once per rising edge, so it holds (2^32 - n * D) mod 2^32 after n edges,
// and it passes through zero exactly once every 2^32 / INCREMENT = 13_500_000 edges.
//
// Simulating 13.5 million clocks proves nothing that a hundred does not, so the testbench overrides the
// rate to 108: D = 54, INCREMENT = 2^32 - 54 = 4_294_967_242. The counter checkpoints below are the
// specification's own arithmetic done from D, so a design with the wrong INCREMENT fails them.
//
//   n = 1       counter = 2^32 - 54        = 4_294_967_242
//   n = 10_000  counter = 2^32 - 540_000   = 4_294_427_296
//   n = 79_503_574 is the edge at which it reaches zero; too many to simulate.
//
// The zero crossing is therefore checked separately, on a design whose increment is a power of two:
// CLOCK_RATE_HZ = 2^31 gives D = 2^30 and INCREMENT = 2^32 - 2^30 = 2^30, so the high bit of the
// counter is the interrupt flag toggling every 4 edges. That is a different instance from the one above,
// and it is the only way to see the crossing inside a short run.

module tb;
    localparam RATE = 108;
    localparam D    = RATE / 2;

    reg  i_clk;
    wire o_led;

    pps #(.CLOCK_RATE_HZ(RATE)) u_dut(.i_clk(i_clk), .o_led(o_led));

    integer edges;
    integer errors;

    always #5 i_clk = ~i_clk;

    task check_at(input integer at);
        reg [31:0] want;
        begin
            want = (32'h0 - (at * D));
            if (u_dut.counter !== want) begin
                $display("FAIL edge %0d: counter = %0d, expected %0d", at, u_dut.counter, want);
                errors = errors + 1;
            end else
                $display("ok   edge %0d: counter = %0d", at, u_dut.counter);
        end
    endtask

    initial begin
        edges = 0;
        errors = 0;
        i_clk = 0;

        // the increment, which is the only place the large clock rate enters the design
        if (u_dut.INCREMENT[31:0] !== (32'h0 - D)) begin
            $display("FAIL: INCREMENT at %0d Hz is %0d, expected %0d",
                     RATE, u_dut.INCREMENT[31:0], (32'h0 - D));
            errors = errors + 1;
        end else
            $display("ok   INCREMENT at %0d Hz = %0d (2^32 - %0d)", RATE, u_dut.INCREMENT[31:0], D);

        // the accumulator, checkpointed at edges 1 and 10_000
        while (edges < 10_000) begin
            @(posedge i_clk);
            #1;
            edges = edges + 1;
            if (edges == 1)     check_at(1);
            if (edges == 10_000) check_at(10_000);
        end

        if (errors == 0) $display("=== tb PASS === pps increment and accumulation");
        else             $display("=== tb FAIL === %0d problem(s)", errors);
        $finish;
    end
endmodule
