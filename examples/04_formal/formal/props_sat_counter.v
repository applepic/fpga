// Formal properties for exercise 02. This file is the acceptance criteria. Do not modify it.
//
// The design under test is sat_counter.v in ../rtl/. The properties below are the
// specification: "the counter counts up while inc is high, and it never goes past 200".
//
// Difference from a testbench: there is no stimulus here. Nothing drives clk, rst or inc.
// The solver picks them. Every always block below is checked at every rising edge,
// for every input sequence the circuit could ever see, not just the one you wrote down.

module formal_top (
    input wire clk,
    input wire rst,
    input wire inc
);
    wire [7:0] count;

    sat_counter u_dut (
        .clk   (clk),
        .rst   (rst),
        .inc   (inc),
        .count (count)
    );

    // A proof has no "time 0" the way a simulation does. The solver is free to start in any
    // state, including a state the real circuit could never reach. So we constrain the first
    // cycle to be a reset cycle; from there on it explores everything.
    //
    // Remove this block and rerun: the proof fails at step 2. That is worth doing once,
    // because it shows what "unconstrained initial state" means in practice.
    reg f_past_valid = 1'b0;
    always @(posedge clk)
        f_past_valid <= 1'b1;

    always @(posedge clk)
        if (!f_past_valid)
            assume (rst);

    // P1: the counter never exceeds 200.
    always @(posedge clk)
        if (f_past_valid && !rst)
            assert (count <= 8'd200);

    // P2: once it reaches 200, it stays there while inc is high.
    always @(posedge clk)
        if (f_past_valid && !rst && !$past(rst) && $past(inc) && $past(count) == 8'd200)
            assert (count == 8'd200);

    // P3: while inc is high and the counter is below 200, it goes up by exactly one.
    always @(posedge clk)
        if (f_past_valid && !rst && !$past(rst) && $past(inc) && $past(count) < 8'd200)
            assert (count == $past(count) + 8'd1);
endmodule
