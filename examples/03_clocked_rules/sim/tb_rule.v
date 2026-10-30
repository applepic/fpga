`timescale 1ns / 1ps

// Acceptance test for Lesson 3 (always, clocks, blocking vs non-blocking).
//
// Run:
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/03_clocked_rules
//
// Two parts, two reports:
//   PART 1  testbench syntax, through a combinational module you write (rules 1-4)
//   PART 2  the clock, through a two-register module you write (rules 5-8)
//
// PART 2 has two specimen cases filled in: expected values in `sheet` / `chg` rows 1 and 2,
// explained in the comments there. The other fourteen rows are x, and filling them in is
// capability checkpoint 2, the first time expected values come from you. Nothing in this file
// computes an expected value: a checker that recomputes the answer with the design's own
// operators is one answer written twice (lessons/README.md).
//
// Every case waits for the same thing, the next rising edge. Whether that is the right stimulus
// for each case is YOUR decision: see the "YOUR PART" block. Which case tests nothing new is
// something this file prints and does not prevent.
//
// While a row is x, PART 2 reports FAIL with the word TODO. That is a table you have not
// filled in, not a bug in your RTL.

module tb;

    // ---------------- PART 1 ----------------

    reg  [2:0] sel = 3'd0;
    wire [1:0] y;

    mux4 u_mux (
        .sel (sel),
        .y   (y)
    );

    // ---------------- PART 2 ----------------

    reg        clk = 1'b0;
    reg        rst = 1'b0;
    reg        en  = 1'b0;
    reg  [1:0] d   = 2'b00;
    wire [1:0] q;

    two_regs u_two (
        .clk (clk),
        .rst (rst),
        .en  (en),
        .d   (d),
        .q   (q)
    );

    // A free-running clock: `clk` starts at 0 and rises at 5, 15, 25, ... ns, so one cycle is
    // 10 ns. 27 MHz on the board would be #18.5 here; nothing below depends on the frequency.
    // Long form, the same clock: always begin #5; clk = ~clk; end

    always #5 clk = ~clk;

    // ---------------- what q actually did ----------------
    // Recorded separately from the printed table, so the printed table does not change when the
    // design changes. `changes` counts every move of q, reset included.
    //
    // q_seen is NOT initialised in its declaration. iverilog evaluates a declaration initialiser
    // before every module's processes have started, so `reg [1:0] q_seen = 2'bxx;` reads q before
    // q exists (it measured 2'bxx even when the design sets q = 0), and the first real value then
    // counts as a change at time 0. `initial q_seen = q;` runs after all of that. Measured both
    // ways on 2026-10-30.

    reg [1:0] q_seen;
    integer   changes = 0;
    initial q_seen = q;

    task record_q;
        begin
            if (q !== q_seen) begin
                q_seen  = q;
                changes = changes + 1;
            end
        end
    endtask

    // ---------------- the sheet ----------------
    // sheet[N]: what q is AFTER the rising edge that case N waits for.
    // chg[N]  : how many times q has changed BY then, from time zero, reset included.
    // 4-bit change count so up to 15 fits; q starts at 0 and there are 16 cases.
    // Case 0 does not wait for an edge, so it has no "after the edge": it is compared with
    // whatever q holds at time zero. `same[N] = 1` marks such a case and routes it to
    // report_same instead of run_case's edge check.

    reg [1:0] sheet [0:16];
    reg [3:0] chg   [0:16];
    reg       same  [0:16];

    // Declared before the tasks that use them: iverilog wants a name declared before the line
    // that mentions it. (Hit while building this file on 2026-10-30.)
    integer i;
    integer errors;

    // ---------------- checks ----------------

    // PART 1. If / case / default is your decision, not the testbench's.
    task check_y;
        input [2:0] sel_i;
        input [1:0] expected;
        begin
            if (y !== expected) begin
                $display("  FAIL rule 1: sel = %0d gives y = %0d, expected %0d", sel_i, y, expected);
                errors = errors + 1;
            end
        end
    endtask

    // PART 2. One call per case. Expected values are not arguments: they are read from the sheet,
    // so the stimulus and the comparison cannot drift apart.
    //   wait_edge = 1 waits for the next rising edge, 0 changes nothing and checks nothing new.
    //   (The argument is not called `edge`: that is a Verilog keyword, and iverilog reports it
    //   as a syntax error on that line. Hit while building this file on 2026-10-30.)
    task run_case;
        input integer case_no;
        input         wait_edge;
        begin
            if (wait_edge) begin
                @(posedge clk);
                #1;                          // 1 ns for the outputs to settle
            end
            record_q;
            if (!wait_edge) begin
                $display("  case %0d: no edge waited for, q = %0d, changes = %0d. This case exercises nothing new: the cycle it was meant to test is the next case's.",
                         case_no, q, changes);
            end
            else if (^sheet[case_no] === 1'bx) begin
                $display("  case %0d: sheet row is still x, fill it in in sim/tb_rule.v", case_no);
                errors = errors + 1;
            end
            else if (q !== sheet[case_no]) begin
                $display("  FAIL rule 6: case %0d, q = %0d after the edge, sheet says %0d",
                         case_no, q, sheet[case_no]);
                errors = errors + 1;
            end
            else if (changes !== chg[case_no]) begin
                $display("  FAIL rule 7: case %0d, q has changed %0d times, sheet says %0d",
                         case_no, changes, chg[case_no]);
                errors = errors + 1;
            end
        end
    endtask

    // Look up the sheet row for `same`. Run after the case's run_case call.
    task report_same;
        input integer case_no;
        begin
            if (^sheet[case_no] === 1'bx) begin
                $display("  case %0d: sheet row is still x, fill it in in sim/tb_rule.v", case_no);
                errors = errors + 1;
            end
            else if (q !== sheet[case_no]) begin
                $display("  FAIL: case %0d, q = %0d with no edge waited for, sheet says %0d",
                         case_no, q, sheet[case_no]);
                errors = errors + 1;
            end
        end
    endtask

    // ---------------- stimulus ----------------

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        // A case is the moment rst / en / d are applied. Cases are back to back, so they land
        // 1 ns after the previous case's edge:
        //
        //     t = 0   start, sheet written, clk = 0, q may still be x
        //     t = 5   rising edge   <- case 1 waits for this
        //     t = 6   case 2 inputs applied
        //     t = 15  rising edge   <- case 2 waits for this, its inputs have been stable 9 ns
        //     t = 16  case 3 inputs applied
        //     ...
        //
        // 2 ns before the first edge there is a start-up window: the design has not seen a
        // clock edge yet. Case 0 below sits in that window.

        // case 0:  nothing has happened yet, the clock has not risen. There is no "after the
        // edge" for this case, so it is marked `same` and report_same checks it: q is compared
        // with the value in sheet[0], which is x unless you write something else. A 2-bit reg
        // starts as x; if your design sets it to 0 at time zero (`initial q = 0;` or
        // `reg q = 0;`), that is a legal design choice, and sheet[0] is where the difference
        // between the two designs shows up.
        same[0] = 1'b1;
        sheet[0] = 2'bxx;  chg[0] = 4'd0;

        // case 1:  rst = 1,  en = 0,  d = 00  -> waits for the RISING edge at 5 ns
        // sheet: q stays at 0 and nothing has changed yet. Reset is high, so no register moves.
        sheet[1] = 2'd0;  chg[1] = 4'd0;  same[1] = 1'b0;
        // case 2:  rst = 1,  en = 1,  d = 11  -> waits for the RISING edge at 15 ns
        // sheet: same answer, and that is the point of having both cases. If rst is wired only
        // into the part en gates, these two cases disagree and the disagreement is the lesson.
        sheet[2] = 2'd0;  chg[2] = 4'd0;  same[2] = 1'b0;
        // cases 3 to 16: yours
        for (i = 3; i <= 16; i = i + 1) begin
            sheet[i] = 2'bxx;
            chg[i]   = 4'bxxxx;
            same[i]  = 1'b0;
        end

        // ================= PART 1: testbench syntax, rules 1-4 =================
        $display("");
        $display("PART 1  testbench syntax, rules 1-4");
        $display("   i | sel |  y");
        $display("-----+-----+-----");

        errors = 0;
        for (i = 0; i < 8; i = i + 1) begin
            sel = i[2:0];
            #10;                                             // rule 2: let the mux settle
            $display("   %0d |  %0d  |  %0d", i, sel, y);      // rule 3: integer with %0d
        end
        // rule 4 is `$display("%s", "...")`: a string up to 200 characters in one piece
        $display("%s", "   (y may depend on sel[1:0] only, never on sel[2]; under 200 chars)");

        // Rule 1: eight expected values, written out by hand from the mapping stated in the
        // lesson. Not the checkpoint-2 rows: the mapping never changes in this course.
        sel = 3'd0; #10; check_y(sel, 2'd0);
        sel = 3'd1; #10; check_y(sel, 2'd2);
        sel = 3'd2; #10; check_y(sel, 2'd1);
        sel = 3'd3; #10; check_y(sel, 2'd3);
        sel = 3'd4; #10; check_y(sel, 2'd0);
        sel = 3'd5; #10; check_y(sel, 2'd2);
        sel = 3'd6; #10; check_y(sel, 2'd1);
        sel = 3'd7; #10; check_y(sel, 2'd3);

        if (errors == 0) $display("  PART 1 PASS");

        // ================= PART 2: the clock, rules 5-8 =================
        $display("");
        $display("PART 2  the clock, rules 5-8");
        $display("  case | rst en  d  | q after | changes | waited for");
        $display("-------+------------+---------+---------+-----------");

        errors = 0;

        // case 0: start-up window, no edge waited for.
        rst = 1'b1; en = 1'b0; d = 2'b00;
        $display("     0 |  %0d  %0d  %0d  |    ?    |    ?    | nothing, q should still be x", rst, en, d);
        run_case(0, 1'b0);
        report_same(0);

        // case 1: first rising edge.
        $display("     1 |  %0d  %0d  %0d  |    ?    |    ?    | rising", rst, en, d);
        run_case(1, 1'b1);

        // case 2: second rising edge.
        rst = 1'b1; en = 1'b1; d = 2'b11;
        $display("     2 |  %0d  %0d  %0d  |    ?    |    ?    | rising", rst, en, d);
        run_case(2, 1'b1);

        // ------------------------------------------------------------------
        // YOUR PART.
        //
        // 1. Build the table by hand first: sixteen rows, columns rst / en / d / q after /
        //    changes. q starts at 0 after case 1, the clock rises once per case from here on,
        //    and case 0 has already told you what q is before the first edge.
        // 2. Write the two numbers into the sheet, next to the case.
        // 3. Decide, for each case, whether waiting for the next rising edge is the right
        //    stimulus, and say why in a comment. Two cases before yours are back to back with
        //    no edge between them, so the example above already has a case that checks the
        //    same cycle twice. Which one, and which of your sixteen is the same trap?
        // 4. Report the result like case 1 and 2 do. That print statement is yours to write.
        //
        // Line shape:
        //     // case 3: rst = 0, en = 0, d = 01
        //     sheet[3] = 2'd?; chg[3] = 4'd?;
        //     rst = 1'b0; en = 1'b0; d = 2'b01;
        //     $display(...);
        //     run_case(3, 1'b1);
        // ------------------------------------------------------------------

        // case 3:  rst = 0,  en = 0,  d = 01
        rst = 1'b0; en = 1'b0; d = 2'b01;
        $display("     3 |  %0d  %0d  %0d  |    ?    |    ?    | rising", rst, en, d);
        run_case(3, 1'b1);

        // case 4:  rst = 0,  en = 0,  d = 10
        rst = 1'b0; en = 1'b0; d = 2'b10;
        run_case(4, 1'b1);

        // case 5:  rst = 0,  en = 1,  d = 01
        rst = 1'b0; en = 1'b1; d = 2'b01;
        run_case(5, 1'b1);

        // case 6:  rst = 0,  en = 1,  d = 10
        rst = 1'b0; en = 1'b1; d = 2'b10;
        run_case(6, 1'b1);

        // case 7:  rst = 1,  en = 0,  d = 10
        rst = 1'b1; en = 1'b0; d = 2'b10;
        run_case(7, 1'b1);

        // case 8:  rst = 0,  en = 0,  d = 11
        rst = 1'b0; en = 1'b0; d = 2'b11;
        run_case(8, 1'b1);

        // case 9:  rst = 0,  en = 1,  d = 00
        rst = 1'b0; en = 1'b1; d = 2'b00;
        run_case(9, 1'b1);

        // case 10: rst = 1,  en = 0,  d = 11
        rst = 1'b1; en = 1'b0; d = 2'b11;
        run_case(10, 1'b1);

        // case 11: rst = 0,  en = 1,  d = 01
        rst = 1'b0; en = 1'b1; d = 2'b01;
        run_case(11, 1'b1);

        // case 12: rst = 1,  en = 0,  d = 00
        rst = 1'b1; en = 1'b0; d = 2'b00;
        run_case(12, 1'b1);

        // case 13: rst = 0,  en = 1,  d = 10
        rst = 1'b0; en = 1'b1; d = 2'b10;
        run_case(13, 1'b1);

        // case 14: rst = 1,  en = 0,  d = 01
        rst = 1'b1; en = 1'b0; d = 2'b01;
        run_case(14, 1'b1);

        // case 15: rst = 0,  en = 1,  d = 11
        rst = 1'b0; en = 1'b1; d = 2'b11;
        run_case(15, 1'b1);

        // case 16: rst = 0,  en = 0,  d = 00
        rst = 1'b0; en = 1'b0; d = 2'b00;
        run_case(16, 1'b1);

        if (errors == 0) $display("  PART 2 PASS");

        $finish;
    end

endmodule
