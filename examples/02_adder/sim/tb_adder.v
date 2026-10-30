`timescale 1ns / 1ps

// Acceptance test for Lesson 2 (binary arithmetic). Not yours to write yet:
// capability checkpoint 1 is still open, so I write this one.
//
// Run:
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/02_adder
//
// It applies all eight input combinations of a, b and c_in, and checks sum and
// c_out against the truth table in the lesson.
//
// The expected values are written out by hand from that table (3 * 8 = 24 cells,
// 16 of them 1 in the lesson). They are NOT computed as a + b + c_in, because a
// checker that recomputes the answer with the hardware's own arithmetic is the
// same-origin problem tb_gates had.
//
// This file checks the first four rules. Rules 5 and 6 (two's complement, sign
// extension) are checked by your own testbench, examples/02_adder/sim/README.md.

module tb;

    reg  a = 1'b0, b = 1'b0, c_in = 1'b0;
    wire sum, c_out;

    full_adder u_dut (
        .a     (a),
        .b     (b),
        .c_in  (c_in),
        .sum   (sum),
        .c_out (c_out)
    );

    integer i;
    integer errors = 0;
    reg e_sum, e_cout;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        $display("");
        $display("  a  b c_in | sum c_out");
        $display("------------+----------");

        // {a, b, c_in} as a 3-bit number: 0 = 000, 1 = 001, 7 = 111.
        // Equivalent to: for c_in, for b, for a. i[0] is the last bit, so i[0] is a.
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, c_in} = i[2:0];
            #10;

            $display("  %b  %b  %b  |  %b    %b", a, b, c_in, sum, c_out);

            case (i)
                0: begin e_sum = 1'b0; e_cout = 1'b0; end   // 0+0+0 = 0
                1: begin e_sum = 1'b1; e_cout = 1'b0; end   // 1+0+0 = 1
                2: begin e_sum = 1'b1; e_cout = 1'b0; end   // 0+1+0 = 1
                3: begin e_sum = 1'b0; e_cout = 1'b1; end   // 1+1+0 = 2 (10)
                4: begin e_sum = 1'b1; e_cout = 1'b0; end   // 0+0+1 = 1
                5: begin e_sum = 1'b0; e_cout = 1'b1; end   // 1+0+1 = 2 (10)
                6: begin e_sum = 1'b0; e_cout = 1'b1; end   // 0+1+1 = 2 (10)
                7: begin e_sum = 1'b1; e_cout = 1'b1; end   // 1+1+1 = 3 (11)
            endcase

            if (sum !== e_sum) begin
                $display("    FAIL sum   expected %b, got %b", e_sum, sum);
                errors = errors + 1;
            end
            if (c_out !== e_cout) begin
                $display("    FAIL c_out expected %b, got %b", e_cout, c_out);
                errors = errors + 1;
            end
        end

        $display("");
        if (sum === 1'bx || c_out === 1'bx) begin
            $display("=== FAIL === an output is x: a wire is never driven");
        end
        else if (errors == 0) begin
            $display("=== tb PASS === all 8 rows match");
        end
        else begin
            $display("=== %0d mismatch(es) in tb, see the FAIL lines above ===", errors);
        end

        $finish;
    end

endmodule
