`timescale 1ns / 1ps

// 第 1 课的验收标准。不要改这个文件。
//
// 跑法：
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/00_gates
//
// 它做两件事：
//   1. 把 a b 的四种组合都试一遍，逐个检查四个输出对不对
//   2. 打印一张真值表，你可以拿去和数电课本上的对照

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
            #10;                    // 等组合逻辑算完

            $display("  %b  %b |  %b    %b    %b    %b", a, b, y_and, y_or, y_xor, y_not);

            exp_and = a & b;
            exp_or  = a | b;
            exp_xor = a ^ b;
            exp_not = ~a;

            if (y_and !== exp_and) begin
                $display("    FAIL y_and 应为 %b，实际 %b", exp_and, y_and);
                errors = errors + 1;
            end
            if (y_or !== exp_or) begin
                $display("    FAIL y_or  应为 %b，实际 %b", exp_or, y_or);
                errors = errors + 1;
            end
            if (y_xor !== exp_xor) begin
                $display("    FAIL y_xor 应为 %b，实际 %b", exp_xor, y_xor);
                errors = errors + 1;
            end
            if (y_not !== exp_not) begin
                $display("    FAIL y_not 应为 %b，实际 %b", exp_not, y_not);
                errors = errors + 1;
            end
        end

        $display("");
        if (errors == 0) $display("=== 全部通过 ===");
        else             $display("=== %0d 处不符，看上面的 FAIL 行 ===", errors);

        $finish;
    end

endmodule
