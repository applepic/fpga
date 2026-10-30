`timescale 1ns / 1ps

// Acceptance test for tutorial lesson 02 (maskbus).
//
// Every expected value below was computed BY HAND from the specification in
// examples/tutorial/02_maskbus/README.md, not by running the mask through XOR here. That rule is in
// AGENTS.md #6 ("expected values must never be recomputed from the same operators the RTL uses").
//
// The vector table is the specification tables' rows 0x150, 0x087 and 0x0F0 plus the four edges
// (all zero, all one, single bit set, the mask itself), 10 rows in total.

module tb;
    reg  [8:0] i_sw;
    wire [8:0] o_led;

    maskbus u_dut(.i_sw(i_sw), .o_led(o_led));

    integer k;
    integer errors;
    reg [8:0] vectors [0:9];
    reg [8:0] expected [0:9];

    initial begin
        vectors[0] = 9'h000; expected[0] = 9'h087;
        vectors[1] = 9'h087; expected[1] = 9'h000;
        vectors[2] = 9'h0f0; expected[2] = 9'h077;
        vectors[3] = 9'h150; expected[3] = 9'h1d7;
        vectors[4] = 9'h1ff; expected[4] = 9'h178;
        vectors[5] = 9'h001; expected[5] = 9'h086;
        vectors[6] = 9'h010; expected[6] = 9'h097;
        vectors[7] = 9'h080; expected[7] = 9'h007;
        vectors[8] = 9'h0ff; expected[8] = 9'h078;
        vectors[9] = 9'h100; expected[9] = 9'h187;

        errors = 0;
        $display(" i_sw | o_led | expected |");
        $display("------+-------+----------+");
        for (k = 0; k < 10; k = k + 1) begin
            i_sw = vectors[k];
            #1;
            if (o_led === expected[k])
                $display(" %3h  |  %3h  |   %3h    | ok", i_sw, o_led, expected[k]);
            else begin
                $display(" %3h  |  %3h  |   %3h    | FAIL (got %0d, expected %0d)",
                         i_sw, o_led, expected[k], o_led, expected[k]);
                errors = errors + 1;
            end
        end

        if (errors == 0) $display("=== tb PASS === all 10 rows match");
        else             $display("=== tb FAIL === %0d of 10 rows wrong", errors);
        $finish;
    end
endmodule
