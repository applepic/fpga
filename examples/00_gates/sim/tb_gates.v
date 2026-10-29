`timescale 1ns / 1ps

// Acceptance test for Lesson 1. Do not modify this file.
//
// Run:
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/00_gates
//
// It does two things:
//   1. Tries all four combinations of a and b, checking each of the four outputs
//   2. Prints a truth table you can compare against your textbook
//
// The expected values are a hardcoded table copied from the truth table in the
// lesson, NOT recomputed from the operators. That matters: if the checker
// recomputed `exp_and = a & b` it would just be the answer written twice, and a
// wrong checker would silently enforce a wrong answer. A literal table comes
// from the specification instead. (Fixed 2026-10-28 after the user asked where
// the expected values come from.)

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

    integer i;
    integer errors = 0;
    reg exp_and, exp_or, exp_xor, exp_not;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        $display("");
        $display("  a  b | and  or  xor  not");
        $display("-------+------------------");

        for (i = 0; i < 4; i = i + 1) begin
            {a, b} = i[1:0];
            #10;                    // let the combinational logic settle

            $display("  %b  %b |  %b    %b    %b    %b", a, b, y_and, y_or, y_xor, y_not);

            // The specification, one row per input combination.
            case (i)
                0: begin exp_and = 1'b0; exp_or = 1'b0; exp_xor = 1'b0; exp_not = 1'b1; end
                1: begin exp_and = 1'b0; exp_or = 1'b1; exp_xor = 1'b1; exp_not = 1'b1; end
                2: begin exp_and = 1'b0; exp_or = 1'b1; exp_xor = 1'b1; exp_not = 1'b0; end
                3: begin exp_and = 1'b1; exp_or = 1'b1; exp_xor = 1'b0; exp_not = 1'b0; end
            endcase

            if (y_and !== exp_and) begin
                $display("    FAIL y_and expected %b, got %b", exp_and, y_and);
                errors = errors + 1;
            end
            if (y_or !== exp_or) begin
                $display("    FAIL y_or  expected %b, got %b", exp_or, y_or);
                errors = errors + 1;
            end
            if (y_xor !== exp_xor) begin
                $display("    FAIL y_xor expected %b, got %b", exp_xor, y_xor);
                errors = errors + 1;
            end
            if (y_not !== exp_not) begin
                $display("    FAIL y_not expected %b, got %b", exp_not, y_not);
                errors = errors + 1;
            end
        end

        $display("");
        if (errors == 0) $display("=== ALL PASS ===");
        else             $display("=== %0d mismatch(es), see the FAIL lines above ===", errors);

        $finish;
    end

endmodule
