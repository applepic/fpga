`timescale 1ns / 1ps

// Written by you, at capability checkpoint 1. The original file at this path, tb_gates.v, was
// removed from the repository on 2026-10-30 because you wrote the testbench for your own gates
// exercise, and shipping a working one beside it made the exercise fictional
// (AGENTS.md #6). Nothing is lost: this one checks the same thing, the four outputs of
// examples/00_gates/rtl/gates.v, and you are the one who writes the expected values.
//
// Run:
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/00_gates
//
// When you finish it, tell me and I run the original tb_gates.v (unchanged, from git history;
// it was in commit 40b7d48) against the same design.

module tb;

    reg  a = 1'b0;
    reg  b = 1'b0;
    wire y_and, y_or, y_xor, y_not;

    gates u_dut (
        .a     (a),
        .b     (b),
        .y_and (y_and),
        .y_or  (y_or),
        .y_xor (y_xor),
        .y_not (y_not)
    );

    // ------------------------------------------------------------------
    // YOUR PART.
    //
    // The truth table must come from the specification in the vault lesson
    // (01_Projects/FPGA/Lesson-01-Combinational-Logic.md), which lists the four columns as
    //
    //     y_and  0 0 0 1     y_or  0 1 1 1     y_xor  0 1 1 0     y_not  1 1 0 0
    //
    // Do not compute the expected values with the same operators the design uses
    // (`exp_and = a & b`). Same-origin verification: one shared misunderstanding then passes
    // twice, which is the defect that was found in the old tb_gates.v.
    //
    // Required shape:
    //   1. drive all four combinations of a and b, with a delay before reading each one
    //   2. print a table you can read, with a and b on the left
    //   3. compare each of the four outputs with the specification's column
    //   4. print `=== ALL PASS ===` when there is no mismatch, and a readable FAIL line
    //      naming the output, the expected value and the actual value otherwise
    //   5. finish the simulation, so it does not run forever
    //
    // The syntax you need is in lessons/03_always_and_clocks.md rules 1-4 and in the loop in
    // examples/02_adder/sim/tb_adder.v (`for`, `case`, `integer`, `$display`, `#10`, `$finish`).
    //
    // The old file, for reference on shape only:
    //     git show 40b7d48:examples/00_gates/sim/tb_gates.v
    // Reading it is allowed. Typing it out is not: the expected values must be reasoned from the
    // table above, which is why this file does not contain it.
    //
    // There are no checks below, because every expected value in this file is yours to word.
    // ------------------------------------------------------------------

    integer errors;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        errors = 0;

        // write your stimulus and checks here

        $finish;
    end

endmodule
