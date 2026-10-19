`timescale 1ns / 1ps

// 工具链自检的 testbench：证明仿真这条路也是通的。
//
// 它只做一件事：给 clk 打拍子，然后把 led 的每个 bit 打印出来。
// 全 1 = 板子上全灭，符合设计意图。

module tb;

    reg clk = 1'b0;

    // 27 MHz -> 周期 37.037 ns，仿真里取整成 37 ns，误差可忽略
    always #18.5 clk = ~clk;

    wire [5:0] led;

    top u_top (
        .clk (clk),
        .led (led)
    );

    integer errors = 0;

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb);

        #100;
        $display("led = %b (期望 111111)", led);
        if (led !== 6'b111111) begin
            $display("FAIL: led 不是全 1");
            errors = errors + 1;
        end

        if (errors == 0) $display("PASS: 工具链自检通过");
        else             $display("FAIL: %0d 处不符", errors);

        $finish;
    end

endmodule
