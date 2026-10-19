`timescale 1ns / 1ps

// 练习 01 的 testbench —— 这是你的验收标准，不要改它。
//
// 跑法：
//     . .\env.ps1
//     .\scripts\sim.ps1 -Project examples/01_counter
//
// 它检查三件事：
//   1. 复位时 q = 0
//   2. 每个时钟上升沿 q 加 1
//   3. 数到 15 之后回 0，不卡住、不跳号

module tb;

    reg        clk   = 1'b0;
    reg        rst_n = 1'b0;
    wire [3:0] q;

    // 27 MHz，周期约 37 ns。这里用 10 ns 只是为了让仿真跑得快，
    // 计数器的行为与时钟频率无关。
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

        // ---- 检查 1：复位 ----
        rst_n = 1'b0;
        #22;                        // 两个多时钟周期，够复位生效
        if (q !== 4'd0) begin
            $display("FAIL 检查1: 复位期间 q = %0d，期望 0", q);
            errors = errors + 1;
        end
        else begin
            $display("PASS 检查1: 复位时 q = 0");
        end

        // ---- 检查 2 和 3：连续 20 个周期，覆盖 15 -> 0 的回绕 ----
        rst_n = 1'b1;
        expected = 4'd0;
        for (i = 0; i < 20; i = i + 1) begin
            @(posedge clk);         // 等到上升沿
            #1;                     // 等 1 ns 让输出稳定（避开竞争）
            expected = expected + 4'd1;
            if (q !== expected) begin
                $display("FAIL 检查2/3: 第 %0d 个上升沿后 q = %0d，期望 %0d",
                         i + 1, q, expected);
                errors = errors + 1;
            end
        end
        if (errors == 0) $display("PASS 检查2/3: 20 个周期全部正确（含 15 -> 0 回绕）");

        // ---- 结果 ----
        if (errors == 0) $display("\n=== 全部通过 ===");
        else             $display("\n=== %0d 处不符，看上面的 FAIL 行 ===", errors);

        $finish;
    end

    // 防止设计卡死时仿真跑不完
    initial begin
        #10000;
        $display("FAIL: 仿真超时，设计可能没有正常响应时钟");
        $finish;
    end

endmodule
